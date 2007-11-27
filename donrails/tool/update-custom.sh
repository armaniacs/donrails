#!/bin/sh

# カスタマイズ用のシェルスクリプトをほいっと書いてみました。
# 詳細は中をみてもらうとわかると思います。
#
# customというdirの下に、defaultまたはMTからの必要なファイルをコピーして、
# DonEnv.themeをcustom としてやれば使えます。
#
# DONRAILS_DIR=/home/yaar/donrails-trunk
# DERIVED=default
#
# だけ指定して使ってください。MT由来のならDERIVEDにはMTを書けばいいです。 
#
# このファイル自体は、 ~/.donrails/update-custom.sh にあると想定してます。
# 
# update-custom.tar.gzを展開すると、このファイルと、custom ディレクトリ以下が
# 作成されます。
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
# deployは ~/.donrails/custom/ 以下のファイルを donrailsのtreeに反映します。
#
# clean は donrailsのtreeにあるcustomディレクトリを削除します。
#
# collect は、donrailsのtree以下にある関連 fileを 
# ~/.donrails/custom/ 以下にコピーします。
# 手元で確認したカスタマイズ結果を集めます。
#
# distは必要なファイルの tar ballを作成します。
# distを展開したらDONRAILS_DIRを設定し、 clean して deployします。
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
