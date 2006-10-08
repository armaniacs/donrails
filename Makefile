#!/usr/bin/make

NAME = donrails
VERSION = 1.3.6
TESTDIR = '/tmp/.donrails'

all: link

link: linkrails linkinit links linkj plugin
copy: copyrails copyinit plugin

plugin:
	cd rails; ./script/plugin source http://svn.aviditybytes.com/rails/plugins/
	cd rails; ./script/plugin install security_extensions


linkrails:
	rails rails

copyrails:
	rails -C rails

linkinit:
	cd rails; rm -rf app; ln -s ../donrails/app .
	cd rails; rm -rf lib; ln -s ../donrails/lib .
	cd rails/config; rm routes.rb; ln -s ../../donrails/config/routes.rb .
	cd rails/app/views/layouts; cp -i ../../../../donrails/example/notes.rhtml .
	cd rails/app/views/notes; cp -i ../../../../donrails/example/index.rhtml .

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

clean:
	rm -f *~ */*~ */*/*~ */*/*/*~ */*/*/*/*~ *.orig */*.orig */*/*.orig
	-rm -f $(NAME)-*.tar.gz

dist:	clean
	cd .. ; tar czvf $(NAME)-$(VERSION).tar.gz \
		--exclude .svn \
		--exclude rails \
		--exclude donrails-trunk/donrails/app/views/notes/index.rhtml \
		--exclude donrails-trunk/donrails/app/views/layouts/custom \
		donrails-trunk ; \
		mv $(NAME)-$(VERSION).tar.gz donrails-trunk 

installertest: dist
	-rm -rf $(TESTDIR) && mkdir $(TESTDIR) && cp $(NAME)-$(VERSION).tar.gz $(TESTDIR)
	cd $(TESTDIR) && tar zxvf $(NAME)-$(VERSION).tar.gz 
	cd $(TESTDIR)/donrails-trunk && make
	cp $(TESTDIR)/donrails-trunk/donrails/example/database-installertest.yml $(TESTDIR)/donrails-trunk/rails/config/database.yml
	cp $(TESTDIR)/donrails-trunk/donrails/example/donrails_env.rb $(TESTDIR)/donrails-trunk/rails/config/environments/
	cd $(TESTDIR)/donrails-trunk/rails/db && sqlite3 installertest-development-data.db < ../../donrails/tool/tables-sqlite.sql
	cat $(TESTDIR)/donrails-trunk/donrails/example/.environment.rb >> $(TESTDIR)/donrails-trunk/rails/config/environment.rb
	cd $(TESTDIR)/donrails-trunk/rails && ./script/server -d -p 13001
	curl http://localhost:13001/notes/
	curl -u foo:bar http://localhost:13001/login
