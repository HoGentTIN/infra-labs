# Lab 2: Configuration Management with Ansible

The goal of this assignment is to set up a complete local network (domain name `infra.lan`, IP 172.16.0.0/16) with some typical services: a web application server (e.g. to host an intranet site), DHCP and DNS. A router will connect the LAN to the Internet. The table below lists the hosts in this network:

| Host name         | Alias  | IP             | Function             |
| :---------------- | :----- | :------------- | :------------------- |
| (physical system) |        | 172.16.0.1     | Your physical pc     |
| r001              | gw     | 172.16.255.254 | Router               |
| srv001            | ns,ns1 | 172.16.128.1   | Primary DNS          |
| srv002            | ns2    | 172.16.128.2   | Secondary DNS        |
| srv003            | dhcp   | 172.16.128.2   | DHCP server          |
| srv004            |        | 172.16.128.4   | Monitoring server    |
| srv100            | www    | 172.16.128.100 | Webserver            |
| ws0001            |        | (DHCP)         | workstation          |
| control           |        | 172.16.128.253 | Ansible control node |

A note on the naming convention used: server VMs with name starting with `srv0` host network infrastructure services. VMs with `srv1` host user-facing services (e.g. webserver).

**Warning:** Sometimes students install the `vagrant-vbguest` plugin that is supposed to automatically check whether VirtualBox Guest additions are up-to-date and to install an update if they aren't. However, the base boxes we use don't have the prerequisites (C-compiler, etc.) so this will fail, resulting in the guest additions no longer working. Biggest problem with this is that the /vagrant directory is no longer mounted. In short: you should never install the `vagrant-vbguest` plugin while working on this assignment

## Learning goals

- You can automate the setup of network services with a configuration management system (Ansible)
- You can install and configure reproducible virtual environments (Infrastructure as Code) with suitable tools for the automation of the entire lifecycle of a VM

## Acceptance criteria

- You should be able to reconstruct the entire setup (except the VMs for the router and workstation) from scratch by executing the command `vagrant up`, without any manual configuration afterwards.
- When connecting a workstation VM to the network, it should:
    - get correct IP settings;
    - be able to view the local website using the hostname, not the IP address (also verify that you have installed a custom SSL certificate);
    - have internet access.
- You should be able to ping the hosts in the network by host name (rather than IP address) from the workstation VM.

## 2.1. Set up the control node

Go to the `vmlab` directory and start the Vagrant environment with `vagrant up`. Currently, the environment consists of a single VM with host name `control`. This is the **Ansible control node**. It is the machine from which you will run Ansible to configure the other VMs in the environment.    

**Possible issue for Linux/MacOS users**: you might run into an error concerning the allowed IP-range of host-only networks in VirtualBox. The error message itself is quite self-explanatory: you should create/adapt the `/etc/vbox/networks.conf` file to allow all IP-addresses using the following line:

```config
* 0.0.0.0/0
```

Check that you can log in to the VM with `vagrant ssh control`.

- What is/are the IP addresses of this VM?
- Check the VirtualBox network adapters of the VM and see if you can match the IP addresses with the VirtualBox adapter.
- Which Linux distribution are we running (command `lsb_release -a` or `cat /etc/redhat-release`)? Find some information about this distro!
- What version of the Linux kernel is installed (uname -a)?
- What version of Ansible is installed?
- Check the contents of the direcory `/vagrant/`.

    The contents of this directory correspond with the `vmlab/` directory on your physical system. In fact, it is a shared directory, so changes you make on your physical system are immediately visible on the VM and vice versa.

You can start using the control node to execute Ansible commands. Ensure that you're in the correct directory (`/vagrant/ansible/`) before you do!

Feel free to improve the configuration of the control node to your liking. To make your changes persistent, update the Bash script found in `vmlab/scripts/control.sh`. This script is executed every time the VM is created, or when you run `vagrant provision control`. For example, you can install additional useful commands or Ansible dependencies, customize the bashrc file with command aliases or a fancy prompt, run the Ansible playbooks to configure the managed hosts, etc.

## 2.2. Adding a managed node

Next, we are going to set up our first **managed node**, i.e. a host that is managed by Ansible.

Add a new VM named `srv100` (which will become our web server) to the Vagrant environment by editing the `vagrant-hosts.yml` file in the `vmlab` directory.

```yaml
- name: srv100
  ip: 172.16.128.100
  netmask: 255.255.0.0
  box: bento/almalinux-9
```

Your control node should always be the last VM defined in `vagrant-hosts.yml`. The reason will become apparent at the final stage of this assignment.

Check whether the new VM is recognized by Vagrant by running `vagrant status` and look for the host name in the command output. If it is, start the VM with `vagrant up srv100`. Check that you can log in to the VM with `vagrant ssh srv100`.

In order to communicate with managed nodes, you need to provide Ansible with a list of hosts. This list is called an [inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html). The inventory can be a simple list of host names, but it can also contain additional information like the host's IP address, the user account to log in with, etc. We will use a simple inventory file that contains only the host name of the VM we just created. Create a file `vmlab/ansible/inventory.yml` with the following contents:

```yaml
---
servers:
  vars:
    ansible_user: vagrant
    ansible_ssh_password: vagrant
    ansible_become: true
  hosts:
    srv100:
      ansible_host: 172.16.128.100
```

The first line with `servers:` defines a group of hosts. All server VMs will be added to this group. Later, we'll add another group for the router VM.

The variables section contains a list of variables that apply to all hosts in the group. The variables `ansible_user` specifies the user that Ansible will use to log in to the managed nodes and run commands. The variable `ansible_ssh_private_key_file` specifies the SSH private key that will be used to log in. This one in particular was generated automatically by Vagrant and is also used when you execute `vagrant ssh`. The variable `ansible_become` specifies that Ansible should use `sudo` to run commands with administrator privileges.

The `hosts` section contains a list of hosts that Ansible can manage. You will extend this list later. The `ansible_host` variable specifies the IP address of the host. This is necessary because the host name `srv100` is not known outside the VM: there is no DNS server available (yet!) that knows how to map host name `srv100` to the specified IP address.

To check whether Ansible can communicate with the VM, execute the following command from within the control node, in the `ansible/` directory:

```console
ansible -i inventory.yml -m ping srv100
```

It's possible you get an SSH fingerprint error, which is normal if it's the first time you connect to srv100 through SSH. To resolve this issue, you can manually connect to srv100 through SSH, collect the server's fingerprint or enable an Ansible setting to disable host key checking (don't do this on production systems!).

If this works, you can have Ansible lookup all kinds of information about the managed node with the `setup` module:

```console
ansible -i inventory.yml -m setup srv100
```

The result will be a long list of facts about the managed node. You can also limit the output to a specific fact by specifying the fact name with the `-a` option:

```console
ansible -i inventory.yml -m setup -a "filter=ansible_distribution*" srv100
```

**Remark:** From here on out, you can assume that the command `vagrant` should always be executed from your physical system, in your preferred shell (Bash, Git Bash, PowerShell, ...) and from the directory `vmlabs/` (containing the file `Vagrantfile`). All Ansible commands should be executed from within the control node, from the directory `/vagrant/ansible/` (containing the `site.yml` playbook).

## 2.3 Applying a role to a managed node

Configuring a managed node with Ansible is done by executing a [playbook](https://docs.ansible.com/ansible/latest/playbook_guide/index.html). A playbook is a [YAML](https://yaml.org) file that contains a list of tasks that should be executed on the target system. In our setup, the main playbook is called `site.yml`. It is all but empty now, but you will add to it later.

The easiest way to configure a VM is to apply an existing [role](https://docs.ansible.com/ansible/latest/user_guide/playbooks_reuse_roles.html). A role is a playbook that is written to be reusable. It contains a general description of the desired state of the target system, and you can customize it for your specific case by setting role variables.

Edit `ansible/site.yml` and add the following:

```yaml
---
- name: Configure srv100 # Each task should have a name
  hosts: srv100          # Indicates hosts this applies to (host or group name)
  roles:                 # Enumerate roles to be applied
    - bertvv.rh-base
```

The role [bertvv.rh-base](https://galaxy.ansible.com/ui/standalone/roles/bertvv/rh-base/) is one that is published on [Ansible Galaxy](https://galaxy.ansible.com/), a public repository of Ansible roles. It does some basic configuration tasks for improving security (like enabling SELinux and starting the firewall) and allows the user to specify some desired configuration options like packages to install, users or groups to create, etc. by initializing some role variables. See the role documentation either on Ansible Galaxy (click the Read Me button) or in the role's [public GitHub repository](https://github.com/bertvv/ansible-role-rh-base). It contains an overview of all supported role variables and how to use them.

In order to use this role, you should first install it with the command:

```console
ansible-galaxy install bertvv.rh-base
```

This will download the role and put it in the correct directory (which one?) so Ansible can make use of it. You will add more roles later, so it's a good idea to have a way install them all at once. This can be done by creating a file `ansible/requirements.yml` with the following contents:

```yaml
---
roles:
  - name: bertvv.rh-base
```

You can install all roles listed in this file with the command:

```console
ansible-galaxy install -r requirements.yml
```

Add all roles you will use in this lab assignment to this file. You can also add this command to the `vmlab/scripts/control.sh` script, so the roles are installed automatically when you create the control node!

Next, run the `site.yml` playbook with command:

```console
ansible-playbook -i inventory.yml site.yml
```

Watch the output and see what happens, specifically, which changes were made to the system. If the playbook ran without errors, run it again and check that this time, no changes were applied. What is the name of this property that after the first run, the operation does not change the target system anymore?

The role `bertvv.rh-base` performs several operations to configure the managed node to some desired state. It is possible to customize this desired state by setting so-called role variables. Well written roles have good documentation that explains which variables are available and how to use them. The documentation for `bertvv.rh-base` can be found on [Ansible Galaxy](https://galaxy.ansible.com/ui/standalone/roles/bertvv/rh-base/) (click on the README button) or in the role's [public GitHub repository](https://github.com/bertvv/ansible-role-rh-base).

Variables can be set in a playbook itself, but this would quickly make it very hard to read. It is best practice to initialise variables in a separate file. Ansible looks for variables in some default locations, either in a subdirectory `ansible/group_vars/`  or `ansible/host_vars/`. Host variables will only be visible inside that specific host. For `srv100`, this host variable file should be called `ansible/host_vars/srv100.yml`. Hosts can be ordered into groups, but at this time, this is outside the scope of this assignment. However, there is one special group, called `all`, that contains all hosts that can be managed by Ansible (for now, only `srv100`). This variable file should be called `ansible/group_vars/all.yml`, which is already created. We created a `server` group, so those variables should be stored in `ansible/group_vars/servers.yml`. Open this file and add the following content:

```yaml
# ansible/group_vars/servers.yml
---
rhbase_repositories:
  - epel-release
rhbase_install_packages:
  - bash-completion
  - vim-enhanced
```

These variables will result in the following changes (check the role documentation for details!):

- The package repository EPEL (Extra Packages for Enterprise Linux) is installed and enabled
- The software packages `bash-completion` and `vim-enhanced` are installed

Run the playbook again to bring the VM to the new desired state. Check the output to verify the changes.

Update the variable file so the following useful packages are also installed:

- bind-utils
- git
- nano
- setroubleshoot-server
- tree
- wget

Create a user account for yourself (e.g. your first name, in lowercase letters) with a chosen password. Check the role documentation to see which variable you should use and the correct syntax to initialise it. This user will become an administrator of the system, which means that they should get `sudo` privileges. On a RedHat-like system like the one we're working on, this means that we should add this user to the (already existing) user group `wheel`.

On your physical system, you should already have an SSH key pair (that you use for GitHub). If not, create one by executing the command `ssh-keygen` in a Bash terminal (on Mac/Linux) or Git Bash (Windows) and pressing ENTER until you're back on a shell prompt. Your home directory should contain a directory `.ssh` with a file `id_rsa.pub`. This is your public key. Open the file with a text editor (or print the contents with `cat`) and copy the text. Register this public key file in `all.yml` in the way that is specified in the role documentation. This will allow you to SSH into the VM as your own user without having to specify a password.

Re-apply the role and check the changes. Verify that you can SSH into the VM with your username, without a password. Open a (Bash) shell on your physical system and execute:

```console
ssh USER@IP_ADDRESS
```

where you replace USER with your chosen username (case-sensitive!) and the IP address of your VM on interface `eth1` (starts with 172). The first time you do this, you will get a warning that the authenticity of this host can't be established. Enter `yes` to confirm that you want to continue connecting. You should also be able to log in from your Ansible control node!

Since the previous changes were applied to `group_vars/servers.yml`, every VM that we will add to this will automatically have these same properties.

## 2.4. Web application server

Next, we will configure `srv100` as a web application server. In this assignment, we'll use the `bertvv.rh-base` role to install the necessary packages and start the corresponding services. For a "production environment", you'll probably be using an existing role, or write your own full-fledged role.

### 2.4.1. Installing Apache and MariaDB

The first step is to install the MariaDB database server, the Apache web server (including support for HTTPS), PHP (including the mysqlnd package for connecting to the database). Look up which packages are necessary and add them to the variable `rhbase_install_packages`.

**Pay attention!** Since these packages are only needed on `srv100`, you should *not* specify them in `servers.yml`. Instead, create a file called `ansible/host_vars/srv100.yml` and define the variable `rhbase_install_packages` there. It is important to realise that we now have two places where `rhbase_install_packages` is defined. Ansible will choose the most specific one, i.e. the one defined in `host_vars/srv100.yml`. That means that you should add the packages specified in `servers.yml` to the list in `host_vars/srv100.yml`!

At this point you can run the site playbook again to see if all packages are installed correctly.

### 2.4.2. Make services available

The next step is to make sure that MariaDB and Apache are running and that they will be enabled at boot. Look up the correct variables in the role documentation and set them in `host_vars/srv100.yml`.

The `rh-base` role also supports configuring the firewall. Ensure that the firewall is configured so that the web server is accessible from the outside world. *Note:* it's best practice to specify *services* allowed through the firewall rather than *port numbers*. Remark that the MariaDB service should *not* be exposed to the outside world! It is only used by the PHP application running on the server itself.

Run the playbook again and check the result. Can you access the default web page at <http://172.16.128.100> *and* <https://172.16.128.100>? Is the database server running and can you open a console with `sudo mysql`?

### 2.4.3. PHP application

The directory `ansible/files` contains an SQL script to initialise the database and a PHP-script that queries a database table and shows the result. In this step, we will install the PHP script and ensure that it works correctly when accessed with a web browser.

In `ansible/site.yml`, add a `tasks:` section below `roles:`

```yaml
- name: Configure srv100
  hosts: srv100
  roles:
    - bertvv.rh-base
  tasks:
    # ...
```

An Ansible task is a single action that should be performed on the target system. It is usually structured as follows:

```yaml
- name: Name of the task
  module.name:
    parameter1: value1
    parameter2: value2
```

An Ansible module is a piece of code that performs a specific action. The `module.name` is the name of the module that should be executed. The parameters are specific to the module. There are dozens (if not hundreds) of modules for all kinds of purposes. You can find an [index of all modules](https://docs.ansible.com/ansible/latest/collections/index_module.html) in the Ansible documentation. Bookmark this page, you will need it often!

We'll need to perform the tasks enumerated below. First some advice, though: don't try to do everything at once. Start with the first task, run the playbook, make sure it works *and* verify the result before moving on to the next one. Use the Ansible documentation or find a tutorial on how to write playbooks.

- Copy the database creation script (db.sql) to the server
    - Use module `ansible.builtin.copy`
    - Put the file in `/tmp/`
- Install the PHP script `test.php`
    - Use the copy module again
    - Put the file in the appropriate directory and rename it to `index.php`
    - Verify that you can see the PHP file in a web browser. It won't show the database contents yet, but you should at least see the page title.
- Create the database
    - Use module `community.mysql.mysql_db`
    - As database name, specify a *variable* `db_name`. The variable is initialised in `host_vars/srv100.yml`. The PHP script contains the expected name for the database.
        - The syntax for using a variable is `{{ VARIABLE_NAME }}`, so `{{ db_name }}` in this case
    - Use the suitable module parameters to specify that the database shouls be initialised from the `db.sql` script.
    - Since we're on the same host as the database, it isn't necessary to specify a host, username or password. We can connect using the parameter `login_unix_socket` and specify the socket file. On RedHat-like systems, this is `/var/lib/mysql/mysql.sock`.
    - Verify that the database was created correctly by logging in to the database server with `sudo mysql` and executing the command `show databases;` and a select query on one of the tables.
- Create a database user
    - Use module `community.mysql.mysql_user`
    - As name and password, use the variables `db_user` and `db_password` respectively. These are initialised in `host_vars/srv100.yml` with the expected values found in the PHP script.
    - Ensure that this user has all privileges on the database specified by variable `db_name`
    - Connect using the `login_unix_socket` parameter
    - Verify that the database user exists and that it can be used log in to the database with `mysql -uUSER -pPASSWORD DATABASE` (replace USER, PASSWORD and DATABASE with the correct values), and that you can show the tables and contents.

After these steps, you should see the contents of the database when you open the PHP script in a web browser:

![PHP script showing database contents](img/4-website.png)

### 2.4.4. SSL certificate

Nowadays, a webserver is not complete without supporting HTTPS. This means that the server should have an SSL certificate installed. The default installation of Apache already has a self-signed certificate, but in production use, you would install a certificate from a trusted certificate authority (CA). For this assignment, we will simulate the installation of an SSL certificate, but we'll create one that is self-signed.

The creation of a certificate should not be automated, as it is a step that is performed only once. However, the installation of the certificate can be automated. The role `bertvv.httpd` supports the installation of a certificate. The role documentation explains how to do this.

So, install the necessary tools to generate an SSL certificate, create it, and copy the generated files to the correct location in your Ansible project tree. Then modify the playbook or `hosts_vars` to install the certificate. Finally, verify that the certificate is installed correctly by opening the website with HTTPS.

### 2.4.5. Idempotency

If you run the playbook again, you will notice that the database is re-initialised. Unfortunately, the `mysql_db` module is not *idempotent* when you use the import option. This means that the module will always execute the import script, even if the database already exists. This is not what we want! We only want to execute the import script when we first copy the initialisation script to the server.

There are two ways to solve this problem:

- Redefine the task that creates the database as a "handler". When you copy the database script, "notify" the handler. The handler will only be executed when the task is notified. [Read about handlers](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_handlers.html) in the Ansible documentation.
- In the copy task, use the "register" option to store the result of the task in a variable. Then, in the task that creates the database, use the "when" option to only execute the task when the result has changed. [Read about conditionals](https://docs.ansible.com/ansible/latest/user_guide/playbooks_conditionals.html) in the Ansible documentation.

Implement either method so your playbook becomes idempotent.

## 2.5. DNS

In the next part, you will use the Ansible role `bertvv.bind` to configure a **new** server `srv001` as a DNS server. The role's primarily purpose is to set up an authoritative-only name server that only replies to queries within its own domain. However, it is possible to configure it as a caching name server that either forwards requests to another DNS server, or replies to queries that have been cached.

Don't forget basic security settings, specifically the firewall! Use the `rh-base` role to configure the firewall so that the DNS server is accessible from the outside world.

### 2.5.1. Adding a new VM

Before you can start configuring `srv001` as a DNS server, you first need to create it. Add an entry to `vmlab/vagrant-hosts.yml` for `srv001`. Use the same Vagrant base box as `srv100`, and assign the correct IP address.

Next, add a new section for `srv001` to the `site.yml` file and assign the roles `bertvv.rh-base` and `bertvv.bind`. Don't forget to install this new role on the control node and add it to `requirements.yml`!

Create a file `ansible/host_vars/srv001.yml` for defining role variables specific for this host.

**Tip:** when running the `site.yml` playbook against your environment, it will update the desired state of *all* hosts in the inventory. If you only want to apply the changes to a specific host, you can use the `--limit` option (or `-l` for short). For example, to only apply the changes to `srv001`, you can run:

```console
ansible-playbook -i inventory.yml --limit srv001 site.yml
```

This may save you a lot of time in the remainder of the assignment. You could also comment out code of the hosts that you're not currently working on.

### 2.5.2. Caching name server

Let's now start configuring the new server as a caching nameserver without any authoritative zones. Define the necessary role variables (peruse the role documentation!) to:

- allow any host to send a query to this DNS server
- allow recursion
- set it up as a forward-only server
- list IP addresses of one or two forwarders. Remark:
    - you can forward to the IP address of the DNS-server provided in the VirtualBox NAT network.
    - if you enter an external forwarder (e.g. Quad9), be aware that this may not always be possible from the HOGENT campus. Most of these are firewalled. Instead, you need to use the HOGENT's own DNS servers or one of the few forwarders that are allowed (e.g. Google, Cloudflare). You should be able to find the IP addresses of HOGENT's DNS servers on your own!
- disable DNSSEC (which is important if you set up DNS in production, but this is beyond the scope of this course)

If the service is running, check the following:

- check the service state with `systemctl`
- what sockets/ports are in use? (`ss`)
- check the service logs with `journalctl`
- look at the contents of the main configuration file
- enable query logging
- send a query to the DNS service with `dig` and check if it responds
- send a query from your physical system and check if it responds
- check the logs again, can you see which queries were sent a what response the server gave?

### 2.5.3. Authoritative name server

If your DNS server is available to other hosts in the network, you can move on to the next part, which consists of adding a zone file for our domain, `infra.lan`. Define the variable `bind_zones` and specify:

- the domain name
- the IP subnet(s) associated with this domain
- the primary name server's IP address and name
- hosts within this domain, including their host name, IP address and any aliases.
    - Ensure the DNS server responds to a query for both `www.infra.lan` and `infra.lan`, so that later, client machines will be able to point their browser to `http://www.infra.lan` and `http://infra.lan`.
  
Again, when the service is running, check:

- what changed in the main config file?
- look at the contents of the zone file
- turn on DNS query logging (with `rndc querylog`) and send DNS-requests to the service, both from the VM and from your physical system. Check the logs to see whether these queries were received and how the service responded.
- Try a zone transfer request (e.g. from the control node with `dig`)

### 2.5.4. Secondary name server

In this part, you will set up `srv002` as a secondary name server. This means that it will receive a copy of the zone file from the primary name server and will be able to respond to queries for this domain. This is useful for redundancy: if the primary name server is down or under high load, the secondary name server can still respond to queries.

- Add a host entry for `srv002` to `vmlab/vagrant-hosts.yml`
- Add a new section for `srv002` to `site.yml` and assign the roles `bertvv.rh-base` and `bertvv.bind`
- Create a file `ansible/host_vars/srv002.yml` for defining role variables specific for this host.
- Define the necessary role variables to configure `srv002` as a secondary name server for the domain `infra.lan`. Check the role documentation for details!

When the service is running, check:

- Do the server logs show that a zone transfer was performed?
- Turn on query logging and check if the server responds to DNS requests
- Try the following experiment (while keeping the logs of the secondary DNS server open in a terminal, i.e. add the `-f` option to `journalctl`):
    - Make a change to the zone file for `infra.lan` on the primary name server: add a new host srv101 with IP address 172.16.128.101. Save the file and reload the service.
    - Check whether the primary name server responds to this a query for this host.
    - The secondary name server will *not* respond to this query. Why not? What should be done so a zone transfer is triggered and the secondary name server gets a copy of the updated zone file?
    - Apply this necessary change, and check the logs of the secondary name server for the zone transfer. Check again whether the secondary name server responds to the query.

After this experiment, because of the manual changes, your DNS VMs have "drifted" from their desired state. Revert the changes by running the site playbook again. Verify that the name servers no longer respond to queries for the host `srv101`.

## 2.6. DHCP

In a local network, workstations usually get correct IP settings from a DHCP server. In this part of the lab assignment, you will use the Ansible role `bertvv.dhcp` to configure `srv003` as a DHCP server.

The address space of the internal network is used as follows:

| Lowest address | Highest address | Host type                    |
| :------------- | :-------------- | :--------------------------- |
| 172.16.0.1     | --              | Your physical system         |
| 172.16.0.2     | 172.16.127.254  | Guests (dynamic IP)          |
| 172.16.128.1   | 172.16.191.254  | Servers, gateway (static IP) |
| 172.16.192.1   | 172.16.255.253  | Workstations (reserved IP)   |
| 172.16.255.254 | --              | Router                       |

First, create a new virtual machine named `srv003`. Then configure the DHCP server so workstations that attach to the network get an IP address in the correct range and all other necessary settings to get access to the LAN and the Internet. Lease time is 4 hours.

Some remarks:

- Only hosts with a dynamic or reserved IP address are assigned by the DHCP server!
- A subnet declaration is only needed for the dynamic IP addresses. The reserved IP addresses are configured with host declarations.
- Make sure that the address range specified in your subnet declaration doesn't overlap with the reserved IP addresses!
- A subnet declaration's network IP should match the network part of the DHCP server's IP address, otherwise the daemon will not start.

## 2.7. Managing a router with Ansible (Cisco version)

In the previous parts of this lab assignment, we set up several machines that, when put together, can form a fully functioning local network. There's still a component missing, and that is the router that connects this network with the outside world. So, next, we are going to set up a router and configure it using Ansible.

There are some Vagrant base boxes for router OSs, but most don't work very well. So, for the purpose of this lab assignment, we will have to configure the VM manually. We'll be using a Cisco IOS VM (CSR1000v). If you are enrolled in a Cisco NetAcad academy, you should have access to the following files:

- `VirtualBox ETW-CSR1000v.ova`: base VirtualBox appliance
- `csr1000v-universalk9.17.03.02.iso` (or a newer version), the installation ISO for Cisco IOS

Be aware that the router VM takes 4 GB of RAM!

**If for some reason the Cisco Router VM does not work, you can replace this part of the assignment (2.7) with an alternative assignment that you can find in the file [2.7-router-vyos.md](2.7-router-vyos.md).**

### 2.7.1. Create and boot the router VM

- Import the OVA file in VirtualBox and, optionally, put it in the `vmlab` group (that was automatically created by Vagrant)
- Copy or move the .iso file to the directory that contains the VM (should be something like `${HOME}/VirtualBox VMs/vmlab/CSR1000v`, with `${HOME}` your user's home directory, i.e. `c:\Users\USERNAME` on Windows, `/Users/USERNAME` on Mac or `/home/USERNAME` on Linux).
- Edit the Network settings of the VM.
    - By default, you should have a single active network adapter. Attach it to a NAT interface. After booting, an IP address will be assigned by DHCP (which one?)
    - Enable Adapter 2 and attach it to the Host-only network interface that is also used by your other VMs in this environment. After booting, these interfaces will be set to "administratively down".
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

### 2.7.2. Check the default configuration

Verify the router configuration by showing an overview of the network interfaces and the routing table. Check the port forwarding rules on the NAT interface. Specifically, find on what port SSH traffic is forwarded to. Verify that you can log in on your router with SSH by opening a Bash terminal on your physical system and executing the following command (replace PORT by the forwarded SSH port number of the VM's NAT adapter), and using password `cisco123!`:

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

### 2.7.3. Managing the router with Ansible

In order to manage this VM with Ansible, we will need to update the inventory file. Add a new group `routers` and add the following host to it:

```yaml
---
servers:
  # ...
routers:
  hosts:
    CSR1kv:
      ansible_connection: "ansible.netcommon.network_cli"
      ansible_network_os: "ios"
      ansible_host: "127.0.0.1"
      ansible_port: 5022
      ansible_user: "cisco"
      ansible_password: "cisco123!"
```

Test whether this works by executing the following command:

```console
ansible -i inventory.yml -m ios_facts -a "gather_subset=all" all
```

You should get a lot of output with an overview of the router's configuration in JSON format.

### 2.7.4. Writing the playbook

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

Finally, make sure the running configuration is not lost after rebooting the router. Add a new task to the playbook, execute it and verify that you're still able to ping the router from e.g. your physical machine.

### 2.7.5. Possible extensions

- Configure the firewall on the router, implement a suitable security policy for the network.

## 2.8. Integration: a working LAN

We now have set up all components for a working local network. The final step is to put them all together by booting the router and all VMs. Remark that our setup uses up a lot of RAM, so this will only work if you have enough physical RAM (at least 16 GB recommended).

### 2.8.1. Adding a "workstation" VM

To test whether the LAN actually works, configure a new VirtualBox VM manually and use a pre-configured .ova (e.g. [Kali Linux](https://www.kali.org/get-kali/#kali-virtual-machines), or your favourite Linux distribution from [osboxes.org](https://www.osboxes.org/)). This workstation VM should have enough RAM and processor cores to boot into a graphical user interface and one network adapter. Attach the adapter to the VirtualBox Host-only Interface used by the other VMs in your lab environment.

If you boot the VM:

- the DHCP-server should provide it with an IP address in the correct range, the correct IP addresses for the default gateway and DNS server.
- When you open a web browser in the VM, you should have Internet access (open any website)
- You should be able to view the website on `srv100` by entering `https://www.infra.lan/` in the web browser.

Verify that the IP address is in the correct range (the one reserved for guests with a dynamic IP). Reconfigure the DHCP server so your workstation VM will receive a reserved IP address (also in the correct range!).

### 2.8.2. Reproducibility

This is probably the most scary part of the assignment. You will now destroy all VMs (`vagrant destroy`) and rebuild them from scratch (`vagrant up`). Before you do, make sure you have committed all changes to your playbooks and variable foles to your Git repository! Also, update the provisioning script of the control node so that it also installs the roles specified in `requirements.yml` and runs the `site.yml` playbook on all VMs. If the control node is the last one in the `vagrant-hosts.yml` file, all managed nodes already exist and the playbook should be able to run correctly. Run the playbook a second time to ensure it is idempotent.

This is a good test to see whether your configuration is reproducible. If you did everything correctly, you should end up with a working LAN again!

### 2.8.3. Possible extensions

- **Use Vagrant SSH keys to log in to the VMs.** Vagrant generates private keys that can be used instead of a password for logging in. Conveniently, the private keys are visible inside the control node in the directory `/vagrant/.vagrant/machines/VMNAME/virtualbox/private_key`. Unfortunately, it's not possible to use these directly. If you would replace the line
  
  `ansible_ssh_password: vagrant`
  
  in the `inventory.yml`  file with
  
  `ansible_ssh_private_key_file: ../.vagrant/machines/srv100/virtualbox/private_key`

  when your physical system is Windows, you will get an error that the permissions of the private key are insecure. A private key's permissions should be set to `0600`, but all files in the `/vagrant` directory (which is basically an NTFS volume mounted from the physical system) will be shown as `0777` without a possibility to change this.

  However, you could rewrite the `control.sh` script so it copies the private keys of all managed nodes to the appropriate location on the control node and sets the correct permissions. You can then use the variable `ansible_ssh_private_key_file` in the inventory file to specify the location of each private key.

## Reflection

Remark that in this lab assignment, we actually only scratched the surface of what you can accomplish with Ansible (or any configuration management system, for that matter).

If you don't find the features you need for the computer systems that you manage in existing Ansible Galaxy roles, you'll have to write your own playbooks. Or you may want to write your own reusable role to deploy a specific application on different platforms. This is outside the scope of this course, but you can find ample documentation on how to do this.

The Vagrant environment we created runs on our laptop, but it should be relatively easy to run the playbook on production systems. What we need to accomplish this, is another inventory file that, instead of specifying how to control the VirtualBox VMs, lists the necessary settings for contacting the production machines. You "only" need the IP addresses, an account with administrator privileges with the corresponding password or SSH key.

System administrators use two main approaches when they need to repeatedly set up new machines. The first approach is to (manually or automatically) configure a single system, and save an image of the hard disk in a safe place. [Packer](https://www.packer.io) is a tool that could be used for this purpose. If a new system has to be set up, they take this "**golden image**", make any necessary (hopefully small) changes and release into production. Docker is an example of this approach, with Docker Hub being the main source of golden images. Configuration changes to containers running in production are infeasible. These systems are considered to be **immutable**. When an upgrade is necessary, newly created containers with the desired changes are spun up, while the old ones are taken down.

The other approach is what you did in this lab assignment: use a **configuration management system**. This approach implies that the system administrator will never perform manual changes on a production system. If changes must be applied, the description of the desired state is changed and the playbook is re-applied. **Idempotence** guarantees that only the necessary changes are performed. The system can remain in production, often with no/little downtime.

Both approaches (golden image vs config management) have their place, and a system administrator will choose between them as appropriate for their specific situation. You can even combine both approaches, e.g. starting with Packer to create a Vagrant base box (= golden image) and then then use Ansible to install and configure the necessary software.

The end goal is the same in all cases: the setup of a server must be reproducible and automated as much as possible.
