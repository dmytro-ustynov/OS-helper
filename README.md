# OS-helper

## Ubuntu installation

Set `/boot` approximately 0.5 - 1Gb

Set `[SWAP]` equal to your RAM

Set `/home` approximately 60% of total disk

Set `/` all  of the rest space

No empty space left on disk

## User management

1. Create one more user and make it root

```bash
useradd vasya
```

This will add user `vasya` to the system

2. Set password for the user

```bash
sudo passwd vasya
```
Then enter the password

3. OPTIONALLY. you may set password expiration date for the user
```bash
passwd -e vasya 
```

```bash

4. Make user `vasya` root

```bash
usermod -aG sudo vasya
```
Options  means `-a` -- append to `-G` group `sudo` for user `vasya`

Options `-a` and `-G` splits together to `-aG`

## File and disk commands

Create a file:
```bash
touch file.txt
```
Creates empty file if not exist, otherwise updates the timestamp of file access time (atime)

Create a file in text redactor:
```bash
nano file.txt
```

Will open `file.txt` in nano redactor, if file not exist, it will be created.

Starting nano without filename will create empty file, and after editing on exit will ask which filename to save.

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
ssh dmytro@172.20.10.6
ssh: connect to host 172.20.10.6 port 22: Connection refused
```
Connect to the server with the new port
```bash
ssh -p 3005 dmytro@172.20.10.6
```

## Copy file via SSH


## from remote to local
```bash
scp -P 2002 ssh-admin@192.168.1.105:/home/ssh-admin/host-copy-file.txt ~/programm/tutorials/OS_tutorial 
```


## from local to remote
```bash
scp -P 2002 ~/programm/tutorials/OS_tutorial/OS-helper/README.md ssh-admin@192.168.1.105:/home/ssh-admin/
```