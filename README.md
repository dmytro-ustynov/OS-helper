# OS-helper

## Ubuntu installation

Set /boot approx 0.5 - 1Gb
Set [[SWAP]] equal to your RAM
Set /home approxim 60% of total disk
Set / all  of the space

No empty space left on disk

## User management

1. Create one more user and make it root


   

## File and disk commands



## SSH connection

### Install SSH server
```bash
sudo apt-get install openssh-server
```

### Change SSH port
Edit ssh configuration file:

```bash
sudo nano /etc/ssh/sshd_config
```
In the file change `# Port 22` to `Port 3005` for example , set <30NN> where NN - is your number in Journal

Check ufw
```bash
sudo ufw allow 3005
```
```bash
sudo ufw status
```
If you try to connect, error will be shown, because of the ssh is running on another port
```bash
sh dmytro@172.20.10.6
ssh: connect to host 172.20.10.6 port 22: Connection refused
```
Connect to the server with the new port
```bash
ssh -p 3005 dmytro@172.20.10.6
```

