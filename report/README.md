# Lab reports

This directory contains all your lab reports, written in [Markdown](https://guides.github.com/features/mastering-markdown/). The contents of this repository are English, but feel free to write your own report in Dutch!

**Writing correct Markdown is quite easy, so please take some effort to learn it!** A good text editor like VSCode has support for writing Markdown (e.g. HTML preview, code style checking, cleanup of tables, etc.). Make use of this, so you're certain that when you push your reports to GitHub, they are formatted correctly.

Remark that the table of contents above doesn't work out of the box, as you haven't written your reports yet. Copy the file `report-template.md` to a new file, e.g. `1-report-containers.md` for the first lab assignment.

**Keep a cheat sheet with all commands you're using regularly.** This will help you when you can't remember a particular command during a demo, or when you're working on your assignments.

## Formatting Tips

- You can start learning about Markdown by [reading this guide](https://guides.github.com/features/mastering-markdown/) from GitHub.
- GitHub documentation has a comprehensive [section on Markdown](https://docs.github.com/en/github/writing-on-github) and its specific extensions to standard Markdown syntax
- You can also read the [original documentation on Markdown](https://daringfireball.net/projects/markdown/)

### Don't create screenshots of terminal sessions

Inserting images is time-consuming, and it is completely unnecessary in the case of interacting with a text-based terminal. Markdown has a feature called [fenced code blocks](https://docs.github.com/en/github/writing-on-github/working-with-advanced-formatting/creating-and-highlighting-code-blocks). Just copy the text in the terminal and paste it in your Markdown document. If you specify the language of the code, syntax highlighting is enabled.

Here's an example. Be sure to check both the source code and how it's rendered in HTML!

```console
$ vagrant status
Current machine states:

dockerlab                 running (virtualbox)

The VM is running. To stop this VM, you can run `vagrant halt` to
shut it down forcefully, or you can run `vagrant suspend` to simply
suspend the virtual machine. In either case, to restart it again,
simply run `vagrant up`.
```

The advantage is that this takes less space than an image, and you can still copy/paste the commands in a terminal!

## Inserting images

You can insert images with the following code:

```markdown
![alt text](path/to/image.jpg)
```

Replace "alt text" with a description of the image (an image caption, in fact). The path to the image itself is specified between the parentheses `()`. Remark that you can use relative paths. For your convenience, create a subdirectory named e.g. `img` to store all screenshots and images you want to include in your report. A good text editor will help you with completing the path to the image. E.g. in VS Code, start typing the name of your image directory and press `Ctrl+Space`. It will show a dropdown list with overview of all images, including a preview.

## Formatting tables

Markdown tables are formatted using the "pipe symbol", `|`, e.g.:

```markdown
|     Lorem      | ipsum dolor                        |
| :------------: | :--------------------------------- |
|    sit amet    | markdownum exclamant renarrant     |
| obvius admissa | Dryopen cognita desectum *et modo* |
```

Keeping the pipe symbols aligned is not mandatory. If you remove all the spaces, it renders exactly the same:

```markdown
| Lorem | ipsum dolor |
| :------------: | :--- |
| sit amet | markdownum exclamant renarrant |
| obvius admissa | Dryopen cognita desectum *et modo* |
```

The rendered version looks like:

| Lorem | ipsum dolor |
| :------------: | :--- |
| sit amet | markdownum exclamant renarrant |
| obvius admissa | Dryopen cognita desectum *et modo* |

Obviously, if you look at the second version of the table in the Markdown source, this isn't very readable. No worries, a good text editor can format Markdown tables and align the pipe symbols. E.g. in VSCode, `Alt+Shift+F` will reformat the current document (`Ctrl+Shift+I` on Linux). Check the documentation of the *Markdown All in One* extension for more info.
