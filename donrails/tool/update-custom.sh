#!/bin/sh

# �������ޥ����ѤΥ����륹����ץȤ�ۤ��äȽ񤤤Ƥߤޤ�����
# �ܺ٤����ߤƤ�餦�Ȥ狼��Ȼפ��ޤ���
#
# custom�Ȥ���dir�β��ˡ�default�ޤ���MT�����ɬ�פʥե�����򥳥ԡ����ơ�
# DonEnv.theme��custom �Ȥ��Ƥ��лȤ��ޤ���
#
# DONRAILS_DIR=/home/yaar/donrails-trunk
# DERIVED=default
#
# �������ꤷ�ƻȤäƤ���������MTͳ��Τʤ�DERIVED�ˤ�MT��񤱤Ф����Ǥ��� 
#
# ���Υե����뼫�Τϡ� ~/.donrails/update-custom.sh �ˤ�������ꤷ�Ƥޤ���
# 
# update-custom.tar.gz��Ÿ������ȡ����Υե�����ȡ�custom �ǥ��쥯�ȥ�ʲ���
# ��������ޤ���
#
# find ~/.donrails/custom/
# ~/.donrails/custom/
# ~/.donrails/custom/views
# ~/.donrails/custom/views/layouts
# ~/.donrails/custom/views/layouts/custom
# ~/.donrails/custom/views/layouts/custom/notes.rhtml
#
# Usage: sh ./$SCRIPTNAME {deploy|clean|collect|dist}"
#
# deploy�� ~/.donrails/custom/ �ʲ��Υե������ donrails��tree��ȿ�Ǥ��ޤ���
#
# clean �� donrails��tree�ˤ���custom�ǥ��쥯�ȥ�������ޤ���
#
# collect �ϡ�donrails��tree�ʲ��ˤ����Ϣ file�� 
# ~/.donrails/custom/ �ʲ��˥��ԡ����ޤ���
# �긵�ǳ�ǧ�����������ޥ�����̤򽸤�ޤ���
#
# dist��ɬ�פʥե������ tar ball��������ޤ���
# dist��Ÿ��������DONRAILS_DIR�����ꤷ�� clean ���� deploy���ޤ���
DONRAILS_DIR=/home/yaar/donrails-trunk
DERIVED=default
SCRIPTNAME=update-custom.sh

case "$1" in
    deploy)
	cd custom/views && cp -rvi * $DONRAILS_DIR/app/views
	cd $DONRAILS_DIR/app/views/notes && install -d custom && cp -viu $DERIVED/*.rhtml custom
	cd $DONRAILS_DIR/app/views/shared && install -d custom && cp -viu $DERIVED/*.rhtml custom
	;;
    clean)
	rm -rvf $DONRAILS_DIR/app/views/{layouts,notes,shared}/custom
	;;
    collect)
	cd custom/views/layouts/custom && cp -rviub $DONRAILS_DIR/app/views/layouts/custom/*.rhtml .
	;;
    dist)
	tar zcvf update-custom.tar.gz custom $SCRIPTNAME
	;;
    *)
	echo "Usage: sh ./$SCRIPTNAME {deploy|clean|collect|dist}" >&2
	exit 1
	;;
esac

exit 0
