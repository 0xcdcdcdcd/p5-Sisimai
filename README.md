         ____  _     _                 _ 
        / ___|(_)___(_)_ __ ___   __ _(_)
        \___ \| / __| | '_ ` _ \ / _` | |
         ___) | \__ \ | | | | | | (_| | |
        |____/|_|___/_|_| |_| |_|\__,_|_|
                                 

What is Sisimai ? | シシマイ?
=============================

Sisimai is a core module of bounceHammer version. 4, is a Perl module for 
analyzing email bounce. "Sisimai" stands for SISI "Mail Analyzing Interface".

"シシマイ"はbounceHammer version 4の中核となるエラーメール解析モジュールです。
Version 4なので"シ"から始まりマイ(MAI: Mail Analyzing Interface)を含む名前になりました。

Differences between ver.2 and ver.4 | 新旧の違い
-----------------------------------------------
The followings are the differences between version 2 (bounceHammer 2.7.X) and
version 4 (Sisimai).

| Features                                  | ver 2.7.X | Sisimai | Description |
|-------------------------------------------|-----------|---------|-------------|
| Command line tools                        | OK        | N/A     |             |
| Modules for Commercial MTAs               | N/A       | OK      |             |
| Parse 2 or more bounces in a single email | Only 1st  | ALL     |             |
| Install using cpan or cpanm command       | N/A       | OK      |             |

公開中のbouncehammer version 2.7.12とversion 4(シシマイ)は上記のような違いがあります。

| 機能                                      | ver 2.7.X | Sisimai | 備考        |
|-------------------------------------------|-----------|---------|-------------|
| コマンドラインツール                      | あり      | 無し    |             |
| 商用MTA解析モジュール                     | 無し      | あり    |             |
| 2件以上のバウンスがあるメールの解析       | 1件目だけ | 全件対応|             |
| cpanまたはcpanmコマンドでのインストール   | 非対応    | 対応済  |             |


System requirements | 動作環境
------------------------------

* Perl 5.10.1 or later

Dependencies | 依存モジュール
-----------------------------
Sisimai relies on:

* __Class::Accessor::Lite__
* __Try::Tiny__
* __JSON__

Sisimaiは上記のモジュールに依存しています。

Install | インストール
----------------------

    % sudo cpanm Sisimai

OR
    
    % cd /usr/local/src
    % git clone https://github.com/azumakuniyuki/Sisimai.git
    % cd ./Sisimai
    % sudo cpanm .


Basic usage | 基本的な使い方
----------------------------
make() method provides feature for getting parsed data from bounced email 
messages like following.

```perl
use Sisimai;
my $v = Sisimai->make( '/path/to/mbox' );   # or Path to Maildir

if( defined $v ) {
    for my $e ( @$v ) {
        print ref $e;                   # Sisimai::Data
        print $e->recipient->address;   # kijitora@example.jp
        print $e->reason;               # userunknown

        my $h = $e->damn();             # Convert to HASH reference
        my $j = $e->dump('json');       # Convert to JSON string
        print $e->dump('json');         # JSON formatted bounce data
    }
}
```

上記のようにSisimaiのmake()メソッドをmboxかMaildirのPATHを引数にして実行すると
解析結果が配列リファレンスで返ってきます。

REPOSITORY | リポジトリ
-----------------------
[github.com/azumakuniyuki/Sisimai](https://github.com/azumakuniyuki/Sisimai)

WEB SITE | サイト
-----------------
[bounceHammer | an open source software for handling email bounces](http://bouncehammer.jp/)

AUTHOR | 作者
-------------
azumakuniyuki

COPYRIGHT | 著作権
------------------
Copyright (C) 2014 azumakuniyuki <perl.org@azumakuniyuki.org>,
All Rights Reserved.

LICENSE | ライセンス
--------------------
This software is distributed under The BSD 2-Clause License.

