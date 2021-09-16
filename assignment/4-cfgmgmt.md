# Lab 4: Configuration Management with Ansible

TODO: intro

The goal of this assignment is to set up a complete local network (domain name `infra.lan`) with some typical services: a web application server (e.g. to host an intranet site), DHCP and DNS. A router will connect the LAN to the Internet. The table below lists the hosts in this network:

| Host name         | Alias | IP             | Function         |
| :---------------- | :---- | :------------- | :--------------- |
| (physical system) |       | 172.16.0.1     | Your physical pc |
| r001              | gw    | 172.16.255.254 | Router           |
| srv001            | ns1   | 172.16.128.1   | Primary DNS      |
| srv002            | ns2   | 172.16.128.2   | Secondary DNS    |
| srv003            | dhcp  | 172.16.128.3   | DHCP server      |
| srv010            | www   | 172.16.128.10  | Webserver        |
| ws0001            |       | (DHCP)         | workstation      |

## 3.0. Learning goals

TODO

## 3.1. Set up the lab environment

Go to the `vmlab` directory and start the Vagrant environment, currently consisting of a single VM with host name `srv010` (which will become our web server). The last few lines of the output shows that an Ansible Playbook was run. You can find that playbook in the subdirectory [vmlab/ansible/site.yml](../vmlab/ansible/site.yml). Currently, this playbook is all but empty, so nothing really happens. Verify in the output that no changes were applied to the VM (look for the text `changed=0`).

Check that you can log in to the VM with `vagrant ssh srv010`. What is/are the IP addresses of this VM? Which Linux distribution are we running (command `lsb_release -a`)? Find some information about this distro! What version of the Linux kernel is installed (uname -a)?

## 3.2. Basic server setup

The easiest way to configure a VM is to apply a [role](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html). A role is a playbook that is written to be reusable. It contains a general description of the desired state of the target system, and you can customize it for your specific case by setting role variables.

Edit `ansible/site.yml` and add the following:

```yaml
---
- hosts: all    # Indicate hosts this applies to (host or group name)
  roles:        # Enumerate roles to be applied
    - bertvv.rh-base
```

The role [bertvv.rh-base](https://galaxy.ansible.com/bertvv/rh-base) is one that is published on [Ansible Galaxy](https://galaxy.ansible.com/), a public repository of Ansible roles. It does some basic configuration tasks for improving security (like enabling SELinux and starting the firewall) and allows the user to specify some desired configuration options like packages to install, users or groups to create, etc. by initializing some role variables. See the role documentation either on Ansible Galaxy (click the Read Me button) or in the role's [public Github repository](https://github.com/bertvv/ansible-role-rh-base). It contains an overview of all supported role variables and how to use them.

TODO: script that installs roles

When you execute the command `vagrant provision srv010`, the playbook `site.yml` will be executed and the role will be applied to the VM. Check the output to verify that some changes (how many and which ones?) were applied to the system.

Variables can be set in a playbook itself, but this would quickly make it very hard to read. However, you can create separate variable files on some default locations, either in a subdirectory `ansible/group_vars/`  or `ansible/host_vars/`. Host variables will only be visible inside that specific host. For `srv010`, this host variable file should be called `ansible/host_vars/srv010.yml`. Hosts can be ordered into groups, but at this time, this is outside of the scope of this assignment. However, there is one special group, called `all`, that contains all hosts that can be managed by Ansible (for now, only `srv010`). This variable file should be called `ansible/group_vars/all.yml`, which is already created. Open this file and add the following content:

```yaml
# ansible/group_vars/all.yml
---
rhbase_repositories:
  - epel-release
rhbase_install_packages:
  - bash-completion
  - vim-enhanced
```

These variables will result in the following changes:

- The package repository EPEL (Extra Packages for Enterprise Linux) is installed and enabled
- The software packages `bash-completion` and `vim-enhanced` are installed

Run `vagrant provision pr010` again to bring the VM to the new desired state. Check the output to verify the changes.

Update the variable file so the following useful packages are also installed:

- bind-utils
- git
- nano
- tree
- wget

Create a user account for yourself (e.g. your first name, in lowercase letters) with a chosen password. Check the role documentation to see which variable you should use and the correct syntax to initialise it. This user will become an administrator of the system, which means that they should get `sudo` privileges. On a RedHat-like system like the one we're working on, this means that we should add this user to the (already existing) user group `wheel`.

On your physical system, you should already have an SSH key pair (that you use for Github). If not, create one by executing the command `ssh-keygen` in a Bash terminal (on Mac/Linux) or Git Bash (Windows) and pressing ENTER until you're back on a shell prompt. Your home directory should contain a directory `.ssh` with a file `id_rsa.pub`. This is your public key. Open the file with a text editor (or print the contents with `cat`) and copy the text. Register this public key file in `all.yml` in the way that is specified in the role documentation. This will allow you to SSH into the VM as your own user without having to specify a password.

Re-apply the role and check the changes. Verify that you can SSH into the VM with your user name, without a password. Open a (Bash) shell on your physical system and execute:

```console
ssh USER@IP_ADDRESS
```

where you replace USER with your chosen user name (case sensitive!) and the IP address of your VM on interface `eth1` (starts with 172). The first time you do this, you will get a warning that the authenticity of this host can't be established. Enter `yes` to confirm that you want to continue connecting.

Since the previous changes were applied to `group_vars/all.yml`, every VM that we will add to our environment will automatically have these properties.

## 3.3. Web application server

Next, we will configure `srv010` as a web application server. We start with the database backend (MariaDB), followed by the web server (Apache) and finally a PHP application (Wordpress).

### 3.3.1. MariaDB database server

Use the `bertvv.mariadb` role to install [MariaDB](https://mariadb.org/) (a fork of MySQL) on the VM and specify the following properties:

- create a database for Drupal (e.g. `wordpress`);
- create a user (e.g. `wordpress`) that has all privileges (except GRANT) on all tables in `wordpress` with a strong, randomized password.

Verify that the user and database exist by logging in to the MySQL database and showing databases and users:

TODO: check the following!

```console
[vagrant@srv010 ~]$ sudo mysql -uroot
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 34
Server version: 10.3.28-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| wordpress          |
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
4 rows in set (0.001 sec)

MariaDB [(none)]> select user,host,password from mysql.user;
+-----------+-----------+-------------------------------------------+
| user      | host      | password                                  |
+-----------+-----------+-------------------------------------------+
| root      | localhost |                                           |
| root      | 127.0.0.1 |                                           |
| root      | ::1       |                                           |
| wordpress | localhost | *D37C49F9CBEFBF8B6F4B165AC703AA271E079004 |
+-----------+-----------+-------------------------------------------+
4 rows in set (0.000 sec)

MariaDB [(none)]> 
```

Also check whether the wordpress database can be accessed by the user.

```console
[vagrant@srv010 ~]$ mysql -uwordpress -pPASSWORD wordpress

```

### 3.3.2. Apache web server

The next step is to install the Apache webserver, using the `bertvv.httpd` role.

The web server should support encrypted communication over HTTPS. When installing HTTPS support for Apache, a default server key and certificate are installed (in `/etc/pki/tls/private` and `/etc/pki/tls/certs`, respectively). [Generate a new (self-signed) certificate](https://wiki.centos.org/HowTos/Https) and ensure that it is installed on the webserver, and that Apache is configured to use that, rather than the default. Remark that generating the certificate should not be part of your Ansible playbook. Create the certificate once, manually. Then copy the necessary files to the correct location within the directory containing your Ansible playbook (usually a subdirectory `files/`). Your Vagrant/Ansible project directory is mounted inside your VM under `/vagrant/`, so it's easy to copy the generated files to the appropriate directories.

Verify that the website is available to users by surfing to the appropriate IP addres in a webbrowser on your physical system. Don't forget that you may have to configure the firewall (`bertvv.rh-base` supports this).

### 3.3.3. Wordpress

Finally, use the `bertvv.wordpress` role to install Wordpress on the VM. The Wordpress site should be visible under *https://IP_ADDRESS/wordpress/*.

## 3.4. DNS

TODO

## 3.5. DHCP

In a local network, workstations usually get correct IP settings from a DHCP server. In this part of the lab assignment, you will use the Ansible role `bertvv.dhcp` to configure `srv003` as a DHCP server.

The address space of the internal network is used as follows:

| Lowest address | Highest address | Host type                    |
| :------------- | :-------------- | :--------------------------- |
| 172.16.0.1     | --              | Your physical system         |
| 172.16.0.2     | 172.16.127.254  | Guests (dynamic IP)          |
| 172.16.128.1   | 172.16.191.254  | Servers, gateway (static IP) |
| 172.16.192.1   | 172.16.255.253  | Workstations (reserved IP)   |
| 172.16.255.254 | --              | Router                       |

Configure the DHCP server so workstations that attach to the network get an IP address in the correct range and all other necessary settings to get access to the LAN and the Internet. Lease time is 4 hours.

Some remarks:

- Only hosts with a dynamic or reserved IP address are assigned by the DHCP server!
- Make sure that you don't have an overlap between the address range in your subnet declaration!
- A subnet declaration's network IP should match the DHCP server's IP address, otherwise the daemon will not start.

## 3.6. Router

In the previous parts of this lab assignment, we set up several machines that, when put together, can form a fully functioning local network. There's still a component missing, and that is the router that connects this network with the outside world. So, next, we are going to set up a router and configure it using Ansible.

There are some Vagrant base boxes for router OSs, but most don't work very well. So, for the purpose of this lab assignment, we will have to configure the VM manually. We'll be using a Cisco IOS VM (CSR1000v). If you are enrolled in a Cisco NetAcad academy, you should have access to the following files:

- `VirtualBox ETW-CSR1000v.ova`: base VirtualBox appliance
- `csr1000v-universalk9.17.03.02.iso` (or a newer version), the installation ISO for Cisco IOS

Be aware that the router VM takes 4GB of RAM!

### Create and boot the router VM

- Import the OVA file in VirtualBox and, optionally, put it in the `vmlab` group (that was automatically created by Vagrant)
- Copy or move the .iso file to the directory that contains the VM (should be something like `${HOME}/VirtualBox VMs/vmlab/CSR1000v`, with `${HOME}` your user's home directory, i.e. `c:\Users\USERNAME` on Windows, `/Users/USERNAME` on Mac or `/home/USERNAME` on Linux).
- Edit the Network settings of the VM.
    - By default, you should have a single active network adapter. Attach it to a NAT interface. After booting, an IP address will be assigned by DHCP (which one?)
    - Enable Adapter 2 and attach it to the Host-only networkinterface that is also used by your other VMs in this environment. After booting, these interfaces will be set to "administratively down".
    - The Adapter Type must be set to **Paravirtualized Network (virtio-net)**
- Boot the VM. You should see a GRUB boot menu. Choose the default option or wait until it is selected automatically.
- The installation process will now begin. This will probably take a while! The VM will reboot once and the installation-ISO will be ejected. If everything went ok, you should see the following text:

```text
*                                           *
**                                         **
***                                       ***
***  Cisco Networking Academy             ***
***   Emerging Technologies Workshop:     ***
***    Model Driven Programmability       ***
***                                       ***
***  This software is provided for        ***
***   Educational Purposes                ***
***    Only in Networking Academies       ***
***                                       ***
**                                         **
*                                           *

CSR1kv>
```

### Check the default configuration

Verify the router configuration by showing an overview of the network interfaces and the routing table. Check the port forwarding rules on the NAT interface. Specifically, find on what port SSH traffic is forwarded to. Verify that you can log in on your router with SSH by opening a Bash terminal on your physical system and executing the following command (replace PORT by the forwarded SSH port number), and using password `cisco123!`:

```console
$ ssh -o StrictHostKeyChecking=no -p PORT cisco@127.0.0.1
Password: 

*                                           *
**                                         **
***                                       ***
***  Cisco Networking Academy             ***
***   Emerging Technologies Workshop:     ***
***    Model Driven Programmability       ***
***                                       ***
***  This software is provided for        ***
***   Educational Purposes                ***
***    Only in Networking Academies       ***
***                                       ***
**                                         **
*                                           *

CSR1kv#
```

### Managing the router with Ansible

In order to manage this VM with Ansible, we will need to create an [inventory file](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html). This file contains an overview of all the machines that can be controlled with Ansible, with directions on how to log in, how to get administrator privileges, etc. We haven't talked about this yet, because Vagrant conveniently creates an inventory file for us automatically, and uses it whenever we issue the `vagrant provision` command. Find the inventory file created by Vagrant (tip: it's somewhere inside the `.vagrant/` subdirectory).

We will create an inventory file in Yaml, which is the preferred file format in recent Ansible versions. Put the file in the `ansible/` directory.

```yaml
# Inventory file for accessing a Cisco CSR1000v VirtualBox VM
---
all:
  hosts:
    CSR1kv:
      ansible_connection: "ansible.netcommon.network_cli"
      ansible_network_os: "ios"
      ansible_host: "127.0.0.1"
      ansible_port: 5022
      ansible_user: "cisco"
      ansible_password: "cisco123!"
```

You could add the contents of Vagrant's inventory file to this one if you want to control all VMs directly with Ansible instead of always executing `vagrant provision`.

Test whether this works by executing the following command:

```console
ansible -i inventory.yml -m ios_facts -a "gather_subset=all" all
```

You should get a lot of output with an overview of the router's configuration. Windows users can't do this from their physical system and should log in to one of their Vagrant VMs that should have Ansible installed, and go to the directory that contains the inventory file (somewhere under `/vagrant`).

The `ansible` command can run so-called Ansible modules, the basic building blocks of playbooks, directly from the command-line. The `ios_facts` module will gather information about the Cisco device under control and print it out in JSON format.

### Writing the playbook

Now, we will create the playbook to actually configure our router. Create a file `router-config.yml` in the `ansible/` directory (the one containing the `site.yml` playbook).

```console
# Router configuration playbook
---
- hosts: CSR1kv
  tasks:
    - name: Set interface GE2
      cisco.ios.ios_l3_interfaces:
        config:
          - name: GigabitEthernet2
            ipv4:
              - address: IP_ADDRESS
        state: merged
    - name: Enable GE2
      cisco.ios.ios_interfaces:
        config:
          - name: GigabitEthernet2
            enabled: yes
        state: merged
```

Replace IP_ADDRESS with the actual IP address, in CIDR notation, the router should have.

Now, execute the playbook with:

```console
ansible-playbook -i inventory.yml router-config.yml 
```

from the directory containing your inventory file and router config playbook. Verify that this works by pinging the IP address of the router from any of the VMs in your environment and from the physical system. Also check the router's configuration from the IOS console.

Change the playbook so the Router hostname is set to `r001`. Execute the playbook and verify the result.

## 3.7. Integration: a working LAN

We now have set up all components for a working local network. The final step is to put them all together by booting the router and all VMs. Remark that our setup uses up a lot of RAM, so this will only work if you have enough physical RAM (at least 16GB recommended).

To test whether the LAN actually works, configure a new VirtualBox VM manually and use a pre-configured .ova (e.g. [Kali Linux](https://www.kali.org/get-kali/#kali-virtual-machines), or your favourite Linux distribution from [osboxes.org](https://www.osboxes.org/)). This workstation VM should have enough RAM and processor cores to boot into a graphical user interface and one network adapter. Attach the adapter to the VirtualBox Host-only Interface used by the other VMs in your lab environment.

If you boot the VM:

- the DHCP-server should provide it with an IP address in the correct range, the correct IP addresses for the default gateway and DNS server.
- When you open a web browser in the VM, you should have Internet access
- You should be able to view the website on `srv010` by entering `https://www.avalon.lan/wordpress/` in the webbrowser.

Verify that the IP address is in the correct range (the one reserved for guests with a dynamic IP). Reconfigure the DHCP server so your workstation VM will receive a reserved IP address (also in the correct range!).

## Reflection

Remark that in this lab assignment, we actually only scratched the surface of what you can accomplish with Ansible (or any configuration management system, for that matter).

If you don't find the features you need for the computer systems that you manage in existing Ansible Galaxy roles, you'll have to write your own playbooks. Or you may want to write your own reusable role to deploy a specific application on different platforms. This is outside the scope of this course, but you can find ample documentation on how to do this.

The Vagrant environment we created runs on our laptop, but it should be relatively easy to run the playbook on production systems. What we need to accomplish this, is another inventory file that, instead of explaining how to control the VirtualBox VMs, lists the necessary settings for contacting the production machines. You "only" need the IP addresses, an account with administrator privileges with the corresponding password or SSH key.

TODO: "golden image" (cfr Docker) vs cfgmgmt, idempotency vs immutable servers <https://www.jamasoftware.com/blog/ruminations-on-docker-and-configuration-management/>

## Acceptance criteria

- You should be able to reconstruct the entire setup (except the VMs for the router and workstation) from scratch by executing the command `vagrant up`, without any manual configuration afterwards.
- When booting a workstation VM in the network, it should get correct IP settings and should be able to view the local website (using the hostname, not the IP address) and have internet access.
- You should be able to ping the hosts in the network by host name (rather than IP address)