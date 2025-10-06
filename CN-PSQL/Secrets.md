
# 🐘 CloudNativePG — Credentials, Access, and App Provisioning

## 1. Bootstrap & `initdb` Secrets

### When You Specify Them

If you define these in your cluster manifest:

```yaml
bootstrap:
  initdb:
    database: myapp
    owner: myapp
    secret:
      name: myapp-db-secret
superuserSecret:
  name: postgres-superuser
```

CloudNativePG (CNPG) will:

* use the provided secrets to initialize PostgreSQL with a known superuser password,
* create the `myapp` database and `myapp` owner user,
* store or reference the provided credentials.

### When You **Don’t** Specify Them

If you omit both:

* CNPG automatically runs `initdb` to create a fresh PostgreSQL cluster,
* it **auto-generates** a random password for the `postgres` superuser,
* it stores that password in a **Kubernetes Secret** named:

  ```
  <cluster-name>-superuser
  ```

  in the same namespace as the cluster.

You can inspect it with:

```bash
kubectl get secret <cluster-name>-superuser -n <namespace>
```

To decode the password:

```bash
kubectl get secret <cluster-name>-superuser -n <namespace> \
  -o jsonpath='{.data.password}' | base64 -d
```

---

## 2. Logging Into PostgreSQL

### Option A — Local Pod Login (No Password Needed)

Inside the CNPG Pod, PostgreSQL uses **peer authentication**.

```bash
kubectl exec -it -n <namespace> <cluster-name>-1 -- psql -U postgres
```

This gives you full superuser access *without needing the password*, because the connection is local to the container.

### Option B — Remote Login (Using the Generated Password)

If your cluster spec has:

```yaml
enableSuperuserAccess: true
```

You can connect externally (via port-forward or network):

```bash
kubectl port-forward svc/<cluster-name>-rw 5432:5432 -n <namespace>
psql "host=localhost port=5432 dbname=postgres user=postgres password=<password>"
```

Use the password you retrieved from the secret.

---

## 3. Provisioning a New Application (e.g., AWX, NetBox, etc.)

When adding a new app *after* the cluster is already running (i.e., not via `initdb`):

1. **Obtain admin access**

   * Use `kubectl exec` into a CNPG Pod and connect as `postgres`.
   * Or connect remotely with the superuser password if network access is enabled.

2. **Create the application database and user**

   ```sql
   CREATE ROLE awx_user LOGIN PASSWORD 'somepassword';
   CREATE DATABASE awx OWNER awx_user;
   ```

3. **Create a Kubernetes Secret** in the app’s namespace (e.g., `awx`) containing:

   ```yaml
   username: awx_user
   password: somepassword
   host: <cluster-name>-rw.<cnpg-namespace>.svc
   port: "5432"
   database: awx
   ```

4. **Reference the secret** in the application’s deployment (for example, the AWX Operator’s `postgres_configuration_secret` field).

5. **(Optional)**

   * Use a one-shot Job or CI/CD task to automate these SQL steps and secret creation.
   * Re-run it to rotate passwords or re-provision databases in a declarative way.

---

## 4. Key Points & Best Practices

* Kubernetes Secrets are **namespace-scoped** — apps in other namespaces can’t read CNPG’s internal secrets directly.
* Use **`kubectl exec`** for ad-hoc admin access; it avoids exposing passwords.
* Keep the **superuser Secret** tightly controlled via RBAC.
* Create dedicated, low-privilege users for each application.
* For production, plan for **password rotation** and **network policies** restricting DB access.

---

**In summary:**
If you don’t define any bootstrap secrets, CNPG auto-generates them and stores them as Kubernetes Secrets. You can always log in locally without a password (`kubectl exec … psql -U postgres`), or externally using the generated password if `enableSuperuserAccess` is set.
For new apps, manually create a user and database, store the credentials as a Secret in the app’s namespace, and point the app to the CNPG service endpoint.
