# Install SheepCTL CLI


1) SSH key
    ```
    ssh-keygen -t ed25519 -C "shepherdkey"
    ```
    Result:
        Your identification has been saved in /Users/username/.ssh/id_ed25519
        Your public key has been saved in /Users/username/.ssh/id_ed25519.pub

2) Go to internal Broadcom GitHub in a browser
    * https://github.gwd.broadcom.net
    * Upper right hand corner select down arrow and then settings
    * Select SSH and GPG keys
    * New SSH key
    * Select title: shepherdkey
    * cat /Users/username/.ssh/id_ed25519.pub
    * Paste cat result into window (something like this: ssh-ed25519 AAAABBBBBBBCCCCCCDDDDDDD)

3) Add the key to ssh
    ```
    ssh-add
    ssh-add -l #will show you the key added
    ```
4) Point to the internal GitHub
    ```
    brew tap vmware/internal git@github.gwd.broadcom.net:TNZ/shepherd-homebrew-internal.git
    ```
5) Install stuff
    ```
    brew install sheepctl
    brew install shepherd
    ```
