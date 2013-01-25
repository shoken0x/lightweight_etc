SFAtack
ver.2012.10.29

■使用法
./sfatack thread_num count_down hostname path
 1) thread_num：起動するスレッド数
 2) count_down：実行までのカウントダウン秒数
 3) hostname  ：接続するホストのIPアドレス　★ホスト名ではなくIPアドレス
 4) path      ：HTTP の GET メソッドに与える取得するファイルパス

■使用例
「http://nricis1.wwws.nri.co.jp/index.php に対し、
　5秒のカウントダウン後、10スレッドでアクセスしたい」
場合は下記の通り。IPアドレスは別途取得しておく。

    ./sfatack 10 5 192.218.149.70 /index.php

以上
