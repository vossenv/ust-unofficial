# Unoffical UST Resources

The resources on this page are NOT officially supported by Adobe, but provide additional resources and information.  Any questions regarding the material here can be directed to per38285@adobe.com.

# Installation on the SUSE platforms

Installation of the user sync tool is straightforward.  The install shell script provided [here](https://github.com/janssenda-adobe/UST-Install-Scripts) will allow a quick and easy installation.  The binaries are pulled from this repository, and apply to openSUSE as well as SLES SP1+.

# Building the SUSE platforms

The Suse platforms are not officially supported, but the tool can be successfully compiled and deployed on them. The following instructions work on openSUSE 42.3 and SLES12SP1+.  Other verisons will have very similar processes.  The primary difference is in the versioning of packages, particularly with SLES.  In some cases, openSUSE repositories can be borrowed if needed. If you are using vagrant/virtualbox for your builds, you can get the boxes used for this writeup from the Vagrant Cloud:

[OpenSUSE Leap 42.3](https://app.vagrantup.com/danimaetrix/boxes/openSUSE-Leap-42.3)<br/>
[SLES12 SP1](https://app.vagrantup.com/danimaetrix/boxes/sles12-sp1-sdk)  (w/DVD repositories)<br/>
[SLES12 SP3](https://app.vagrantup.com/danimaetrix/boxes/sles12-sp3-sdk)  (w/DVD repositories)


## Prerequisites

### All versions 
In the case of openSUSE, there are no prerequisites.  However, SLES platforms must have access to the devel repositories.  These can be most easily accessed via the freely available SDK DVD iso files, which can be found on their [official home](https://download.suse.com/index.jsp).  You will need to download the iso file corresponding to your version of SLES -- mixing service pack levels will not work. There are two disks available in each case, denoted by DVD1 and DVD2.  For this process, you only need DVD1 - the other disk contains source packages (and is much larger).  You will not need to access SLES pool repositories for the build process (no need to register the server).  **Note that the boxes linked to above for this build already include these updates, and if using them you can skip the remainder of this section!!!**  
* Your downloaded iso filename should resemble the following (for SLES 12 SP1): 

  ```bash
   SLE-12-SP1-SDK-DVD-x86_64-GM-DVD1.iso
  ```
* Next, copy the iso file onto your SLES VM and place it in a secure location. You can then add it as a repository source using the "zypper ar" command:
    
    ```bash
    sudo zypper ar iso:/?iso=/path/to/SLE-XX-SPX-SDK-DVD-x86_64-GM-DVD1.iso "SLES SDK DVD"
    ```
    
* At this point you should refresh the repository list so the new packages can be included. Run "sudo zypper ref", and ignore any warnings about expiring tokens - they will not reappear after the initial refresh!

### <br/>SLES SP1 and lower 
The older versions of SLES are not able to meet some of the system dependency version requirements for the user sync build using their normal SDK repositories. In particular for SP1 the *glib2-devel* package has a maximum version of 2.38, but the build requires > 2.40.  In this (and similar) cases, it is possible to borrow from the openSUSE repositories.  It is recommended to install the packages that are needed, and immediately remove the repository to avoid risk of future conflicts. 

* You can add the following repository to satisfy these requirements:
    ```bash
    sudo zypper ar -f http://download.opensuse.org/distribution/leap/42.3/repo/oss/ "openSUSE OSS repo"
    ```
* Call "sudo zypper ref" to update the list, and accept the key when prompted.  You can then install the updated version of glib2-devel as follows:

    ```bash
    sudo zypper install glib2-devel
    ```
* Accept the recommended solutions to resolve conflicts, and install the package.  Once complete, your glib version should satisfy the user sync requirements, and the  openSUSE  repository can be easily removed.  To do so, lookup the ID for the repository with "zyyer lr" (see column 1). Once you have the id, you can remove it and refresh. 

    ```bash
    sudo zypper lr
    sudo zypper rr #    -- where # is the repository number from zypper lr
	sudo zypper ref
    ```

## Dependencies
The following are dependencies for building user sync on the suse platforms. They can be separated into system and python specific categories for easier installation.  For more detail on these dependencies and other requirements, please refer to the [official user sync documentation](https://github.com/adobe-apiplatform/user-sync.py). 
  
**System dependencies**
* zlib-devel
* libopenssl-devel
* openldap2-devel
* dbus-1-glib-devel
* libffi-devel
* glib2-devel   

**Python specific dependencies**
* python 
* python-devel
* python-virtualenv
* python-pip
* python-pkgconfig
* dbus-1-python

**<br/>Installation**

Install the system dependencies first using the string below.  Make sure all of them install correctly, as the "-n" flag will answer prompts for conflicts with a negative response, so you may need to install some of them individually if this is the case. 

* For your convenience, you can simply copy paste the following into your console:

     ```bash
     sudo zypper -n install zlib-devel libopenssl-devel openldap2-devel dbus-1-glib-devel libffi-devel cyrus-sasl-devel glib2-devel
	 ```

* Next, install the python specific dependencies. They can be installed according to which version of python you wish to build for.  The default is python 2, but you can use python 3 instead simply by replacing the words "python" with "python3" in all cases. 

*  In this procedure we use get-pip.py to install an updated version of pip, as pip related packages are not available from the SLES repositories.  

    ```bash
    sudo curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    sudo zypper -n install python python-devel dbus-1-python
	sudo python get-pip.py
    sudo python -m pip install virtualenv pkgconfig
    ```
* Or, for python 3:

Fixes for the pex versioning issue and pip 10 install issue.

https://github.com/adobe-apiplatform/user-sync.py/issues/351
https://github.com/adobe-apiplatform/user-sync.py/issues/354
And that's it! You should be able to follow the standard build process from here: create a virtual environment for your target python version, activate it and make the pex!

## Build

The build process is very straightforward once all the dependencies are in place.  The process is to create a python environment, and run the "make pex" command in the root folder.  

* Clone the source repo (use wget to pull the release if git is not available)
    ```bash
	sudo git clone https://github.com/adobe-apiplatform/user-sync.py.git
    ```

* Create and activate the virtual environment

    ```bash
	cd user-sync.py
    sudo virtualenv venv;
    source venv/bin/activate	
    ```

* Build the pex file.  It will be generated as *dist/user-sync*.

    ```bash
	sudo make pex
    ```

