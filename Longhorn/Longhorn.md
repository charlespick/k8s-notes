# Longhorn - distributed storage

Longhorn is easy to conceptualize and use. I've made a helm install script. **It does require a patch when running on microk8s** which is also included. Should be run after the main deployment finishes. 

You can ingress the dashboard or port forward it temporarily for configuration

``` bash
microk8s kubectl -n longhorn-system get svc # look for longhorn-frontend
```

## Disks
You should make dedicated data disks on each host then format with
``` bash
lsblk # update below with actual /dev/sd#
sudo parted /dev/sdb -- mklabel gpt 
sudo parted -a opt /dev/sdb -- mkpart primary ext4 0% 100%
sudo mkfs.ext4 /dev/sdb1
sudo mkdir -p /mnt/longhorn
echo '/dev/sdb1 /mnt/longhorn ext4 defaults 0 0' | sudo tee -a /etc/fstab
sudo systemctl daemon-reload
sudo mount -a  
```
Then reconfigure them in the longhorn UI