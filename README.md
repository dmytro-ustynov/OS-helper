# OS commands helper

## Ubuntu installation

Set `/boot` approximately 0.5 - 1Gb

Set `[SWAP]` equal to your RAM

Set `/home` approximately 60% of total disk

Set `/` all  of the rest space

No empty space left on disk

## User management

1. Create one more user and make it root

```bash
useradd -m -s /bin/bash vasya
```

`-m` - makes home folder

'-s' - sets the default shell 

This will add user `vasya` to the system.

2. Set password for the user

```bash
sudo passwd vasya
```
Then enter the password

3. OPTIONALLY. you may set password expiration date for the user
```bash
passwd -e vasya 
```

OPTIONALLY . you may install `fish` as your default shell for the user


```bash
sudo apt-get install -y fish
```

To use it: 

add in the /etc/passwd for this user or edit with usermod:

```bash
sudo usermod -s /usr/bin/fish vasya
```


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

Copy:

`cp <source> <destination>`

Move:

`cp <source> <destination>`

Delete:

`rm path-to-file/file.txt`

delete recursively:

`rm -r folder/`

Create Folder

`mkdir foldername`


Delete Folder

`rmdir foldername`

### Make file executable

To make file executable script, it should be modified with `chmod` command

```bash
chmod +x script.sh
``` 

`.sh` extension is not necessary, but it is a good practice to use it for shell scripts

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

### restart service

```bash
sudo service ssh restart
```

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
scp -P 3005 ssh-admin@192.168.1.105:/home/ssh-admin/host-copy-file.txt ~/programm/tutorials/OS_tutorial 
```

Common syntax is: 
`scp <options> <source> <destination>`

OPTIONS: 

`-P` - (capital P) -- specifies port number

'-r' - copy recursively, e.g. entire folder 

Look closer what `<source>` consist of:

`<username>@<ip_address>:<path>`

`<destination>` -- is path


## from local to remote


The same syntax, but source is your local path, and source is remote
```bash
scp -P 2002 ~/programm/tutorials/OS_tutorial/OS-helper/README.md ssh-admin@192.168.1.105:/home/ssh-admin/
```