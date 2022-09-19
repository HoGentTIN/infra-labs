# Lab 3: Container orchestration with Kubernetes

The goal of this assignment is to become familiar with [Kubernetes](https://kubernetes.io), Google's container orchestration engine.

## Learning goals

TODO

## Acceptance criteria

- Demonstrate that your Kubernetes cluster is running and that you are able to manage it:
    - Open the dashboard to show what's running on the cluster: nodes, pods, services, deployments, etc.
    - Also show these from the command line (using `kubectl`)
- Show all applications that are running on the cluster, both in the web browser and the resources necessary for each application (Pods, Deployments, Services, etc.)
- Show your lab notes and cheat sheet with useful commands

## Additional resources

Kubernetes is a current topic that attracts a lot of interest. That also means that there's a lot of information available and that it's sometimes hard to find good intro-level resources. Here's a small selection that may help you get acquainted with Kubernetes:

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Learning Kubernetes](https://www.linkedin.com/learning/learning-kubernetes/) course at Linkedin Learning. Available for HOGENT students through [Academic Software](https://www.academicsoftware.eu).

If you think you will use Kubernetes professionally, or if you want to gain a much deeper understanding of how it works, the following resources may be of use:

- Martin, P. (2021) *Kubernetes: Preparing for the CKA and CKAD Certifications.* Apress
    - HOGENT staff and students have free access to the ebook from the campus or via VPN [through this link](https://doi.org/10.1007/978-1-4842-6494-2)
- Hightower, K. (2021) *Kubernetes The Hard Way.* Retrieved 2022-09-10 from <https://github.com/kelseyhightower/kubernetes-the-hard-way>
    - Instructions to set up Kubernetes manually. Anyone running Kubernetes in production should know the platform inside out. This guide helps you to install and configure all the necessary components, which is probably the best way to really understand how it works under the hood.

## 3.1. Set up the lab environment

- Install the necessary tools on your physical system (see <https://kubernetes.io/docs/tasks/tools/> for instructions on each desktop platform)
    - `minikube`, a tool to set up a local Kubernetes environment. It's probably best to [use VirtualBox as the driver](https://minikube.sigs.k8s.io/docs/drivers/)

        ```console
        $ minikube config set driver virtualbox
        ```

    - `kubectl`, a command-line tool to run commands against Kubernetes clusters
- Start Minikube with `minikube start` and follow [the instructions in the Minikube documentation](https://minikube.sigs.k8s.io/docs/start/) to get started
- Start the Kubernetes Dashboard:
    - Enable the appropriate Minikube plugins:

        ```console
        $ minikube addons enable metrics-server
        $ minikube addons enable dashboard
        ```

    - Start the Dashboard with `minikube dashboard`
- **Optionally,** use the command `minikube node add` to spin up two extra nodes so you have an actual cluster with a control plane node and two workers.
    - By default, Minikube runs a single Kubernetes (control plane) node. For the purpose of this lab assignment, that's sufficient, but you will get a better feel of how a multi-node cluster works in a multi-node environment (control plane + worker nodes).
    - Remark that there's a command that immediately starts multiple nodes: `minikube start --nodes 3`. However, this command sometimes hangs during execution. Starting nodes individually is more reliable.
    - Also remark that when you're running a multi-node cluster, it may not work very well. When you try to access an application that is running on the cluster, expect that some requests may succeed while others fail.

## 3.2. Basic operation

At this point, we assume you have a running instance of Minikube with at least a control plane node and that `kubectl` is configured to communicate with that instance.

Before you begin, a quick tip: the command `kubectl get all` is very useful to show you everything that is running on your Kubernetes cluster. Whenever you're changing the state of the cluster by creating new objects, you should check the changes with `kubectl get <object-type>` or just `kubectl get all`.

You can get an near real-time view on what happens on your cluster by issuing the following command in a separate Bash terminal:

```console
$ watch -n1 kubectl get all
```

The `watch` command will repeat the `kubectl` command every second (`-n1`) and show the result.

### 3.2.1. Hello world!

- Create your first deployment following the instructions in the [Hello Minikube tutorial](https://kubernetes.io/docs/tutorials/hello-minikube/#create-a-deployment).
- Creating a deployment is not sufficient to make an app available to users. You also [need to create a service](https://kubernetes.io/docs/tutorials/hello-minikube/#create-a-service).
- Check that you can view the app in a webbrowser.

### 3.2.2. Working with manifest files

Usually, you won't be deploying applications with commands like you did in the previous step. You would write a manifest file that describes the desired state of all objects that are needed to run the application. Kubernetes manifest files are written in YAML, which should be familiar to you by now!

In the directory [../kubernetes/3.2.2](../kubernetes/3.2.2), you will find examples of some basic manifest files:

- [echo-deployment.yml](../kubernetes/3.2.2/echo-deployment.yml): describes a deployment for the echo app from the previous step
- [echo-service.yml](../kubernetes/3.2.2/echo-service.yml): describes a service for the echo app
- [echo-all.yml](../kubernetes/3.2.2/echo-all.yml): a file containing both the deployment and service definition.

You will notice that in the last file, some lines only contain `---`. This is YAML syntax to mark the beginning of a new "document" (in YAML terminology). This way, you can combine the definitions of all Kubernetes objects that you want to create in a single YAML file.

Let's deploy the application using the separate files first. Open a terminal in directory `3.2.2/` and follow the instructions below. Be sure to check the result after each command, or use the trick with the `watch` command introduced previously.

```console
$ kubectl apply -f echo-deployment.yml
$ kubectl apply -f echo-service.yml
```

This will first create the Deployment and launch the pods. The second command ensures that the app is available for users. You can do the same thing in one go by combining the code of both files into a single file.

```console
$ kubectl apply -f echo-all.yml
```

Remark that this file is not an exact copy/paste of the previous ones. Indeed, each object should be given a name, and we chose different names for both deployments. Consequently, at this time, two instances of the same app are running at the same time.

Check all components that are currently running, try to access both instances of the service.

If you want to make a change to an existing Kubernetes object, edit the manifest file and run the command:

```console
$ kubectl apply -f <manifest-file.yml>
```

For example, increase the number of replicas of the echoserver app (currently only 1) in the manifest file `echo-all.yml`, and apply the change. Check whether this operation was successful and find out on which node each pod is running (which command can you use for this?). Try to send multiple requests to the service (e.g. curl in a for loop) and check whether all pods process requests by looking at the logs of each pod (with which command).

**Optional:** If one of the nodes in the cluster becomes unavailable (e.g. `minikube node stop minikube-m03). What happens? Is the application still available? Are the pods still running? Is a pod automatically rescheduled to another node? What if you restart the node? Will the cluster "heal" itself completely or not?
