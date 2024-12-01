# *Linux*

## *A short plan of what will be studied*

### Basics:
- **Vim:** skills of working with the editor (how to exit, enable syntax).
- **MC (Midnight Commander):** work with the file manager.
- **Groups and permissions:** setting file rights and user groups.

### Command line:
- **Archives:** work with archives.
- **`grep`:** search for files.
- **`df -h`:** file system information.
- **`ps aux`, `top`, `htop`:** system monitoring.
- **`man`:** command manual.
- **`wget`, `curl`:** download files.
- **Symlink (`ln -s`):** create symbolic links.
- **`&` (`+ screen`):** run commands in the background.

### Remote work with the server:
- **`SSH, SCP, keys id_rsa, id_rsa.pub, authorized_keys`:** remote connect and copy.
- **`/var/log, syslog`:** checking logs to detect errors.

### File system:
- **OS folder structure:** basic concepts about the file system structure.
- **`yum`** and **`apt`:** the principle of operation of package managers and repositories.

### Bash:
- **Basics:** variables and environment.
- **Piping:** passing the results of commands between each other (`tail -f somelog.log | grep hello | grep -v world`).

## Practical tasks:
1. **Launching a server on AWS EC2:** settings, public IP address, domain name.
2. **Creating a user with access via SSH keys and sudo.**
3. **Writing a script to automate user creation.**
4. **Script for archiving files and changing permissions.**
5. **System monitoring (df -h, htop, /var/log logs).**
6. **Configuring Apache and monitoring requests in logs.**
7. **Configuring HTTPS via letsencrypt, redirect to https from nginx.**
8. **Deploy via Docker with persistent data storage.**


### Note: 
**All practical tasks will be performed using the project from the [*NestJS-backend*](https://github.com/Alex-LaNN/NestJS-backend) repository, and the domain name: [*akolomiet.stud.shpp.me*](http://akolomiet.stud.shpp.me/api) will be used to connect to the page.**

### Server Status:
*Please note that the server will not always be in **`Run`** status, so connecting to the site via the domain name may be unavailable for certain periods of time. If you are unable to connect, the server may be currently down.*


### Bonus:
- **CI/CD with TeamCity:** *test and deployment automation.*
- **Service monitoring via Zabbix.**
- **File storage on AWS S3.**
- **Load balancing via AWS Load Balancer.**
- **Working with Route53 for domain management.**
- **Docker Compose for working with multiple containers.**
- **Learning Caddy as an alternative to Nginx.**
