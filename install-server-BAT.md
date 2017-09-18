###INSTALL THIRD-PARTY PACKAGES - Option 1
        #http://wiki.bacula.org/doku.php?id=howto_compile_and_install_bacula_with_bat_on_fedora_7_or_centos_5
export PATH=/usr/lib64/qt4/bin/:$PATH
yum install -y qt4 qt4-devel qwt qwt-devel

###INSTALL THIRD-PARTY PACKAGES - Option 2
    #Bacula packages these up for you so you don't have to go directly to the third party websites.
    #The package contains source code for Qt4 and qwt (Graphics drawing package), 
    #..both of which are needed to build bat (Bacula Administration Tool, a GUI console)
    #These packages only work on the director, so don't install on clients.
wget -O- https://sourceforge.net/projects/bacula/files/depkgs-qt/01Jan13/depkgs-qt-01Jan13.tar.gz/download | tar -xzvf - -C /usr/src
        #Sample Output:
            2017-08-09 23:03:00 (5.97 MB/s) - written to stdout [242405641/242405641]
                depkgs-qt/qt-everywhere-opensource-src-4.8.4/translations/assistant_sl.ts
                depkgs-qt/qt-everywhere-opensource-src-4.8.4/translations/linguist_cs.ts
                depkgs-qt/qt-everywhere-opensource-src-4.8.4/translations/qt_de.ts
                depkgs-qt/qt-everywhere-opensource-src-4.8.4/translations/assistant_cs.ts
                depkgs-qt/qt-everywhere-opensource-src-4.8.4/translations/linguist_fr.ts
                depkgs-qt/qt-everywhere-opensource-src-4.8.4/.LICENSE-EMBEDDED-US
                depkgs-qt/qt-everywhere-opensource-src-4.8.4/.LICENSE-EVALUATION-US
                depkgs-qt/Makefile
                depkgs-qt/build-qt4
                depkgs-qt/README
                depkgs-qt/qt4/
                depkgs-qt/qt4/include/
                depkgs-qt/qt4/lib/
                depkgs-qt/qt4/mkspecs/
                depkgs-qt/qt4/plugins/
                depkgs-qt/qt4/bin/
                depkgs-qt/qt4/translations/
                depkgs-qt/INSTALL
                depkgs-qt/qt4-paths
#Enter depkgs-qt directory and install files.
cd /usr/src/depkgs-qt
make
    #There are configuration parameters build into this script, so there's no need to run ./configure first
    #This took 6 minutes to build for me
    #This adds /usr/src/depkgs-qt/qt4/bin to the beginning of $PATH
source /usr/src/depkgs-qt-qt4-paths 
    #this adds the depkgs-qt4 directory to your path. See: http://www.bacula.org/9.0.x-manuals/en/main/Installing_Bacula.html#SECTION001450000000000000000
    #$PATH should be something link: /usr/src/depkgs-qt/qt4/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/root/bin