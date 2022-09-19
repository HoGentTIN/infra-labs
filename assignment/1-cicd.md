# Lab 1: Continuous Integration/Delivery with Jenkins

In this lab assignment, you will learn the basics on how to set up a build pipeline with Jenkins. In this lab assignment, we will leverage Docker as a platform to easily install and run a Jenkins server. Remark that in a real-world setting, you would probably have a dedicated build server.

## Learning Goals

- Installing and running Jenkins in a Docker container
- Creating simple jobs and build pipelines
- Running the pipeline to build and test an application, and to deploy changes in the application

## Acceptance criteria

- Show that you created a GitHub repository for the sample application
- Show that the application is running by opening it in a web browser
- Show the overview of jobs in the Jenkins dashboard
- Make a change to the sample application, commit and push
- Launch the build pipeline and show the change to the application in the browser
- Show your lab report and cheat sheet! It should contain screenshots of consecutive steps and console output of commands you used.

## 1.1 Set up the lab environment

For this lab assignment, we'll be using the `dockerlab` environment. Start the `dockerlab` VM and log in.

You will also need a GitHub repository with a sample application. Create a new Git repository (this can be on your physical system, where Git and access to GitHub is already configured). Some starter code is provided in directory [cicd-sample-app](../dockerlab/cicd-sample-app/).

1. Ensure that Git is configured, e.g. with `git config --global --list` and check that `user.name` and `user.email` are set. If not, make the necessary changes:

    ```console
    git config --global user.name "Bobby Tables"
    git config --global user.email "bobby.tables@student.hogent.be"
    ```

2. Copy the starter code from `cicd-sample-app` to some new directory outside this Git repository. Enter the copied directory and initialise it as a Git repository with `git init`. Commit all code (e.g. `git add .; git commit -m "Initial commit of sample application"`).
3. On GitHub, create a new public repository and record the URL, probably something like `https://github.com/USER/cicd-sample-app/` (with USER your GitHub username).
4. Link your local repository with the one you created on GitHub: `git remote add origin git@github.com:USER/cicd-sample-app.git` (The GitHub page of your repository will show you the exact command needed for this).
5. Push the locally committed code to GitHub: `git push -u origin main`

## 1.2 Build and verify the sample application

1. Log in to the VM with `vagrant ssh` and go to directory `/vagrant/labs/cicd-sample-app`
2. Build the application using the `sample-app.sh` script. The build script will likely not be executable, so keep that in mind. Downloading the image may take a while since it's almost 900 MB. After the build is finished, your application should be running as a Docker container.
3. Verify the app by pointing your browser to <http://192.168.56.20:5050/>. You should see the text "You are calling me from 192.168.56.1" with a blue background.
4. Stop the container and remove it.

## 1.3 Download and run the Jenkins Docker image

1. Download the Jenkins image with `docker pull jenkins/jenkins:lts`
2. Start the Jenkins Docker container:

    ```console
    docker run -p 8080:8080 -u root \
      -v jenkins-data:/var/jenkins_home \
      -v $(which docker):/usr/bin/docker \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v "$HOME":/home \
      --name jenkins_server jenkins/jenkins:lts
    ```

    - Port 8080 is exposed and forwarded to the host system
    - `-u` runs the container as root
    - The first `-v` option mounts a volume for keeping persistent data
    - The second and third `-v` makes the Docker command available inside the Jenkins container. It is necessary to run the container as root to make this work (see the `-u` option).
    - The last line specifies a name for the container and the image to be used
3. The container is started in the foreground. It will emit a password for the admin user generated at random. Record this password somewhere, because remembering will be impossible for most people. If you do forget the password, you can retrieve it from a specific file inside the container with the command `docker exec -it jenkins_server /bin/cat /var/jenkins_home/secrets/initialAdminPassword`)

## 1.4 Configure Jenkins

1. Open a browser tab and point it to <http://192.168.56.20:8080/>. You are asked to enter the administrator password that you recorded in the previous step. Next, Jenkins will ask which plugins you want to have installed. Choose to install the recommended plugins. After this, Jenkins will initialize, which takes some time. You can follow the progress on the web page.
2. When the initialization process finishes, you are redirected to a page that asks you to create an admin user. For now, you can skip this a continued as admin by following the link at the bottom.
3. On the next page, titled "Instance Configuration", just click "Save and Finish" and then "Start using Jenkins".

## 1.5 Use Jenkins to build your application

1. On the Jenkins dashboard, click "Create a new job". Enter a suitable name, e.g. *BuildSampleApp*. Select a "free style project" as job type.
2. The following page allows you to configure the new job. There are a lot of options, so you may be overwhelmed at first.
    - Optionally, enter a description
    - In the section "Source Code Management", select the radio button "Git" and enter the https-URL to your GitHub project, `https://github.com/USER/cicd-sample-app.git`
    - Since your repository is public it is not necessary to enter credentials.
    - The branch to be built should be `*/main` instead of the default `*/master`
    - In the section "Build Steps", click "Add a build step" and select "Execute shell" from the dropdown list. enter `bash ./sample-app.sh`
    - Click "Save". You are redirected to the Jenkins dashboard
3. The dashboard shows an overview of all build jobs. Click the job you just created and in the menu on the left, start a new build job.
    - Hopefully, the build succeeded. Use the overview of build attempts to view the console output of the build process to. If the build process failed this is where you can find error messages that can help to determine the cause.
4. Ensure the application is running by reloading the appropriate browser tab.

Take some time to realise what you did here, because it's actually quite cool! We launched Jenkins in a Docker container, and the result of the build job is another container that runs alongside it! The specific options when we launched the Jenkins container make sure that this is possible.

If you manage a Jenkins instance for a larger development team, you will probably want to install Jenkins on a dedicated build server, either a physical machine, or a full-fledged virtual machine. Consider the Jenkins Docker image as suitable for testing purposes only.

Remark that if you try to run the build job a second time, it will fail. Check the console output to determine the cause!

## 1.6 Add a job to test the application

We will now create another job that runs an acceptance test after the build process has finished.

Before you begin, you need to know the IP address of both the `samplerunning` and `jenkins_server` container. Find the IP address and ensure that the app is available with `curl http://APP_IP:5050/`. The output should contain a line with the client's IP address:

```text
   <h1>You are calling me from 172.17.0.1</h1>
```

Remark that 172.17.0.1 is the IP address of the Docker host, i.e. your `dockerlab` VM. Our acceptance test will consist of running the curl command from the Jenkins server, which will have a different IP address.

1. On the Jenkins dashboard, click "Create a new job". Enter a suitable name, e.g. *TestSampleApp*. Select a "free style project" as job type. Optionally, add a description.
2. Under section "Build Triggers", select checkbox "Build after other projects are built". In the text field "Projects to watch", enter the name of the build job.
3. Under section "Build steps", add a build step of type "Execute shell". Enter the following code:

    ```bash
    curl http://APP_IP:5050/ | grep "You are calling me from JENKINS_IP"
    ```

    replacing `APP_IP` and `JENKINS_IP` with the appropriate IP addresses.
4. Save and run the job to verify if it succeeds

    Jenkins can determine whether the job succeeded or failed using the exit status of the command given. When `grep` finds a matching line in the standard output of `curl`, it will finish with exit status 0 (indicating success). If not, it will have exit status 1 (indicating failure). If the command returns a nonzero exit status, it will consider the job to be failed.

    Remark that this is not exactly a full-fledged acceptance test. In a real-life application, you would probably launch a test suite that has to be installed on the Jenkins server.

    You could write a bash script that's a bit more useful than the command specified above. For example, if the job fails, the console output will not give you any clue as to why. In case of a failure to find the expected IP address in the output of `curl`, you could print the actual output on the console.

5. The Jenkins dashboard should now list both the build and test job. Stop and remove the `samplerunning` container and then launch the build job.

## 1.7 Create a build pipeline

The build process in a real-life application is usually much more complex. A full-fledged Continuous Integration/Delivery (CI/CD) pipeline will usually consist of more steps than the ones discussed here (e.g. linting, static code analysis, unit tests, integration tests, acceptance tests, performance tests, packaging and deployment in a production environment). This lab assignment, probably your first encounter with a CI/CD tool is a bit simpler, but should give you an idea of what's possible.

In the next step, we will set up a complete build pipeline that, if the build and test steps succeed, will launch your application as a Docker container.

1. Go to the Jenkins pipeline and create a new item. Enter an appropriate name (e.g. SampleAppPipeline) and select "Pipeline" as job type. Press OK.
2. Optionally, enter a description and in the Pipeline section, enter the following code:

    ```text
    node {
        stage('Preparation') {
            catchError(buildResult: 'SUCCESS') {
                sh 'docker stop samplerunning'
                sh 'docker rm samplerunning'
            }
        }
        stage('Build') {
            build 'BuildSampleApp'
        }
        stage('Results') {
            build 'TestSampleApp'
        }
    }
    ```

    This build pipeline consists of 3 stages:

    - The currently running container is stopped and removed
    - The build job is launched
    - The acceptance job is launched

    Be sure to enter the correct names of the jobs if you have chosen your own names! Finally, save the pipeline.
3. Next, start a build. Jenkins will show you how each phase of the pipeline progresses. Check the console output of each phase.
4. If the run succeeds, the application should be running. Verify by opening it in a web browser.

## 1.8 Make a change in the application

In this final step, we will make a change in the application, re-launch the build pipeline and view the result in the browser.

1. Go to your local copy of the Git repository with the sample application. Open file `static/style.css` and change the page background color from "lightsteelblue" into whatever you want.
2. Save the file, commit your changes and push them to GitHub.
3. In the Jenkins dashboard, launch the build pipeline.
4. Reload the application in the web browser, it should have a different background colour now!

## Reflection

This lab assignment was much less complex than a real-life build pipeline would be, but you were able to see how Jenkins kan be used to build, test *and* deploy an application automatically.

What would change in a real-life case:

- In this lab assignment, we installed Jenkins inside a Docker container. In real life, it would probably be installed as a package on a dedicated virtual machine or bare metal.
- The Git repository would probably be maintained on the Jenkins build server, or a dedicated internal server instead of GitHub. That opens the possibility to trigger a Jenkins build on each push to the central Git repo.
- If GitHub is used, the repository is likely to be private. In that case, you have to configure Jenkins, so it has the necessary credentials to download the code from GitHub, an [access token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token).
- The build pipeline would probably be much more elaborate, with linting, static code analysis, unit tests, functional, integration, acceptance and performance tests, ...
- Jenkins would probably package the application (if the build succeeded) and upload it to a package repository.
- In this lab, the application is stopped during the build process. This is of course not desirable on a production server. Usually, you would have the application running on multiple web server instances with a load balancer to distribute client requests to each instance. Deploying the application would consist of launching containers with the new version of the code, and removing those with the old version.
- Depending on the situation, it may be decided that the deployment phase is never done automatically, but manually after a successful build. This is the difference between *Continuous Integration* (no automatic deployment) and *Continuous Delivery*.

And we haven't even discussed any necessary changes to a database schema when new code is deployed!

## Possible extensions

- Create a build pipeline for a larger application, e.g. this [todo list app](https://docs.microsoft.com/en-us/visualstudio/docker/tutorials/your-application)
- Make the lab setup persistent, i.e. when you run `vagrant destroy; vagrant up`, you have a functional Jenkins build server again. The sample application and build pipeline should not necessarily be automatically reproduced.
