# Lab 3: Container orchestration with Kubernetes

The goal of this assignment is to become familiar with [Kubernetes](https://kubernetes.io), Google's container orchestration engine.

## Learning goals

TODO

## 3.1. Set up the lab environment

- Install the necessary tools on your physical system (see <https://kubernetes.io/docs/tasks/tools/> for instructions on each desktop platform)
    - `minikube`, a tool to set up a local Kubernetes environment. It's probably best to [use VirtualBox as the driver](https://minikube.sigs.k8s.io/docs/drivers/)
    - `kubectl`, a command-line tool to run commands against Kubernetes clusters
- Start Minikube with `minikube start` and follow [the instructions in the Minikube documentation](https://minikube.sigs.k8s.io/docs/start/) to get started
- **Optionally,** use the command `minikube node add` to spin up two extra nodes so you have an actual cluster.
    - By default, Minikube runs a single Kubernetes (control plane) node. For the purpose of this lab assignment, that's sufficient, but you will get a better feel of how a multi-node cluster works in a multi-node environment (control plane + worker nodes).
    - Remark that there's a command that immediately starts multiple nodes: `minikube start --nodes 3`. However, this command sometimes hangs during setup. Starting nodes individually is more reliable.

## 3.2. Basic operation

TODO