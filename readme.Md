# A universal downloader that downloads files from gemini://, spartan://, nex://, http:// and https:// protocols!

You may find all the implementation details in the src folder.

How to build it and test it?
First, do you have voc? That is, Vishap Oberon Compiler. If not, go ahead to
```
https://github.com/vishapoberon/compiler
```
You may find all the instructions on how to compile and install it on your specific system in the ReadMe.md file.


Afterwards, if you are on a unix based system,
```
git clone git@github.com:svetlanatad/protocols.git
```
Or you can use https to clone as well.
For testing or checking out the progress, in the protocols directory,  run
```
make

```
This should get you all the dependencies. So if you get an error here, it is probably going to be something like "symbol file not found", in that case, search for that module online and place it in the build directory! Then,
```
make tests
```
This should build you the program, it should work if it got all the dependencies correctly.
Try my program with:
```
build/uget protocol://host/path-to-a-file
```
To get a file i like, run

```
build/uget spartan://mozz.us/art.txt
```


If something doesnt run try creating a build directory. Then it should work.
test is the spartan downloader test. dynamictest is the dynamic array structure test, it should create a text file that contains random characters that I appended to it.

I am planning to extend this project into a universal browser that reads files from all the cool and different protocols from the world!



