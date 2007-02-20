#!/usr/bin/make

NAME = donrails
VERSION = 1.5.99.3
TESTDIR = '/tmp/.donrails'

all: link

link: linkrails linkinit links linkj plugin
copy: copyrails copyinit plugin

plugin:
	cd rails; ./script/plugin source http://svn.aviditybytes.com/rails/plugins/
	cd rails; ./script/plugin install security_extensions
	cd rails/vendor/plugins; wget http://www.cosinux.org/~dam/projects/page-cache-test/cache_test-0.2.tar.bz2 && tar jxvf cache_test-0.2.tar.bz2

linkrails:
	rails rails

copyrails:
	rails -C rails

linkinit:
	cd rails; rm -rf app; ln -s ../donrails/app .
	cd rails; rm -rf lib; ln -s ../donrails/lib .
	cd rails; rm -rf test; ln -s ../donrails/test .
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
		--exclude $(PWD)/donrails/app/views/notes/index.rhtml \
		--exclude $(PWD)/donrails/app/views/layouts/custom \
		$(PWD) ; \
		mv $(NAME)-$(VERSION).tar.gz $(PWD)

installertest: dist
	-rm -rf $(TESTDIR) && mkdir $(TESTDIR) && cp $(NAME)-$(VERSION).tar.gz $(TESTDIR)
	cd $(TESTDIR) && tar zxvf $(NAME)-$(VERSION).tar.gz 
	cd $(TESTDIR)/donrails-trunk && make
	cp $(TESTDIR)/donrails-trunk/donrails/example/database-installertest.yml $(TESTDIR)/donrails-trunk/rails/config/database.yml
	cp $(TESTDIR)/donrails-trunk/donrails/example/donrails_env.rb $(TESTDIR)/donrails-trunk/rails/config/environments/
	cd $(TESTDIR)/donrails-trunk/rails/db && sqlite3 installertest-development-data.db < ../../donrails/tool/tables-sqlite.sql
	cat $(TESTDIR)/donrails-trunk/donrails/example/.environment.rb >> $(TESTDIR)/donrails-trunk/rails/config/environment.rb
	cd $(TESTDIR)/donrails-trunk/rails && ./script/server -d -p 13001
	curl -I http://localhost:13001/archives/noteslist
	curl -u foo:bar http://localhost:13001/login

###
mysqltest: dist mysqltest00 mysqltest10

mysqltest00:
	-rm -rf $(TESTDIR) && mkdir $(TESTDIR) && cp $(NAME)-$(VERSION).tar.gz $(TESTDIR)
	cd $(TESTDIR) && tar zxvf $(NAME)-$(VERSION).tar.gz
	cd $(TESTDIR)/donrails-trunk && rails rails

	cd $(TESTDIR)/donrails-trunk/rails; rm -rf app; ln -s ../donrails/app .
	cd $(TESTDIR)/donrails-trunk/rails; rm -rf lib; ln -s ../donrails/lib .
	cd $(TESTDIR)/donrails-trunk/rails; rm -rf test; ln -s ../donrails/test .
	cd $(TESTDIR)/donrails-trunk/rails/config; rm routes.rb; ln -s ../../donrails/config/routes.rb .
	cd $(TESTDIR)/donrails-trunk/rails/app/views/layouts; cp ../../../../donrails/example/notes.rhtml .
	cd $(TESTDIR)/donrails-trunk/rails/app/views/notes; cp ../../../../donrails/example/index.rhtml .
	cd $(TESTDIR)/donrails-trunk/rails/public/stylesheets ; ln -s ../../../donrails/public/stylesheets/*.css .
	cd $(TESTDIR)/donrails-trunk/rails/public/javascripts ; ln -s ../../../donrails/public/javascripts/*.js .
	cd $(TESTDIR)/donrails-trunk/rails; ./script/plugin source http://svn.aviditybytes.com/rails/plugins/
	cd $(TESTDIR)/donrails-trunk/rails; ./script/plugin install security_extensions
	cd $(TESTDIR)/donrails-trunk/rails/vendor/plugins; wget http://www.cosinux.org/~dam/projects/page-cache-test/cache_test-0.2.tar.bz2 && tar jxvf cache_test-0.2.tar.bz2

mysqltest10:
	-mysqladmin drop test -f -u test
	mysqladmin create test -u test

	cd $(TESTDIR)/donrails-trunk/rails/db && mysql -u test test < ../../donrails/tool/tables-mysql.sql
	cp $(TESTDIR)/donrails-trunk/donrails/example/database-mysqltest.yml $(TESTDIR)/donrails-trunk/rails/config/database.yml

	cp $(TESTDIR)/donrails-trunk/donrails/example/donrails_env.rb $(TESTDIR)/donrails-trunk/rails/config/environments/

	cat $(TESTDIR)/donrails-trunk/donrails/example/.environment.rb >> $(TESTDIR)/donrails-trunk/rails/config/environment.rb
	cd $(TESTDIR)/donrails-trunk/rails && ./script/server -d -p 13001
	curl -I http://localhost:13001/archives/noteslist
	curl -u foo:bar http://localhost:13001/login
	
