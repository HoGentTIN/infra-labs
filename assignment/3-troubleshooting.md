# Lab 3. Troubleshooting

During the semester, you will get two troubleshooting lab assignments. At the beginning of the class hours, you will receive a VM (in the form of an .ova file) that contains configuration errors and consequently will not work. The actual assignments will be published later, but you can already prepare for them by following the recommendations below.

## Learning goals

- Find configuration errors in network services by applying a systematic an thorough methodology, based on a bottom-up approach following the layers of the TCP/IP model.
    - Know which properties must be checked on each layer of the protocol stack, and which commands to use
    - Know which commands and/or config file changes to apply in order to fix any deviations from the expected state of the system

## 3.1. Set up the demo environment

Go to the directory containing your local copy of the [demo environment](https://github.com/HoGentTIN/infra-demo/) and enter the subdirectory `troubleshooting/`. Boot the `db` and `web` VMs.

```console
$ cd infra-demo/troubleshooting
$ vagrant up db web
[...]
```

Open the [lecture slides](https://hogenttin.github.io/infra-slides/03-troubleshooting.html) in a browser tab.

## 3.2. Compile a checklist

Use the lecture slides to compile a checklist of all the commands that you need for troubleshooting, e.g. in the file `report/troubleshooting-checklist.md` (you will have to create this file).

Put some structure in the document, e.g. a section for each layer in the TCP/IP protocol stack, a list of all properties to check, and the commands/config files you need for this.

## 3.3. Try out the demo troubleshooting assignment

Use your checklist and the lecture slides to go through the demo troubleshooting assignment. The `db` VM is configured correctly, but the `web` VM has errors.

Execute the necessary commands to check the VM's properties and fix any errors. Verify that after the changes, the VM is in the expected state. At the end of the process, you should be able to see the web page running on `web`:

![](https://hogenttin.github.io/infra-slides/assets/result.png)

## Acceptance criteria

- You do **not** need to show your preparation steps, as described above.
- At the end of each troubleshooting lab assignment, upload your lab report to Chamilo, under Assignments. You will get specific instructions in each assignment.
