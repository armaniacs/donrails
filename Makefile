#!/usr/bin/make

NAME = donrails
VERSION = 1.2.0pre1

all: link

link: linkrails linkinit links linkj 
copy: copyrails copyinit

linkrails:
	rails rails

copyrails:
	rails -C rails

linkinit:
	cd rails; rm -rf app; ln -s ../donrails/app .
	cd rails; rm -rf lib; ln -s ../donrails/lib .
	cd rails/config; rm routes.rb; ln -s ../../donrails/config/routes.rb .

links:
	cd rails/public/stylesheets ; ln -s ../../../donrails/public/stylesheets/*.css .
linkj:
	cd rails/public/javascripts ; ln -s ../../../donrails/public/javascripts/*.js .

copyinit:
	cd rails; rm -rf app; cp -r ../donrails/app .
	cd rails/config; rm routes.rb; cp ../../donrails/config/routes.rb .

imagedumpdir:
	mkdir rails/public/images/dump && chmod a+w rails/public/images/dump

dbdir:
	chmod a+w rails/db


dist10: clean
	cd .. ; tar --exclude .svn --exclude rails --exclude donrails-1.0/app/views/notes/index.rhtml --exclude donrails-1.0/app/views/layouts/notes.rhtml -zcvf donrails-`cat donrails-1.0/VERSION`_`date +%Y%m%d`.tar.gz donrails-1.0/

clean:
	rm -f *~ */*~ */*/*~ */*/*/*~ */*/*/*/*~ *.orig */*.orig */*/*.orig
	-rm -f $(NAME)-$(VERSION).tar.gz

dist:	clean
	cd .. ; tar czvf $(NAME)-$(VERSION).tar.gz \
		--exclude .svn \
		--exclude rails \
		--exclude donrails-trunk/donrails/app/views/notes/index.rhtml \
		--exclude donrails-trunk/donrails/app/views/layouts/notes.rhtml \
		donrails-trunk ; \
		mv $(NAME)-$(VERSION).tar.gz donrails-trunk 

