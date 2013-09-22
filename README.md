#S2 

Input部分の取り付けが終わったので、挙動を一通り移装しようと思う。

* ステップ式にしようか、それとも完全羃的にするか
* WebSocketのon-off周りが電源と一緒
* 接続してきたやつがいたら、ポジションを聞いてpullを行う(このへんはSRがやるべきことなので、イベントのキックだけをS2から行う。connected。)
* out ignited
* out connected

* in codeUpdated
* out pulling
* out pulled (chamber start)
* out tick
* in codeUpdate ..

* in reset
* out unleashed

* 

ターミナルで侵入して文字列を表示できるってことは、同様にsshで繋いで内容をtailで受けたのを出力できるのでは？という考え方が出来るようになった。WebSocketとは違ったラインで動かせれば良いのか。うん。

まず分離しないとなー。

Terminalの機能限定版を実装できればそのまま行けるじゃん。serveされなきゃいけないけど、インターフェースはWebSocket(待ち)よりはラク。ST3だけを書き換える算段を進めるか。


##S2PP spec

SRで受けなくても動くように、単体のアプリケーションとして駆動したい。

* gradleにメモリ的に接続する事が出来るだろうか。
	可能だとしたらルートはどこか。
	zincがどうやって動いているか解ったら、手がある気がする。

* 複数のgradleを起動状態、ビルド開始直前のステータスで“止める”、っつーことがしたい。
	可能だとしたら、留め方はどんな感じか。

んで、実際のSpec

* WebSocketServerを持つ
* 転送データの最小化、編集行の送信
* msgpackでの圧縮
* CompileChamberを作成し、キャッシュしたデータとかからアクセス可能にする
* chamberへと投入したデータが安定し次第、差分検知後のコードとして動作させる
* Chamberは連装式。常にmaxだけ持つことで、スピンアップタイムをなくす。
* プルファイル、定期的な実ファイルリロードを行い、キャッシュを更新する(save時)
* エラーの解決を行う(pull仕切れなくて発生するエラーとか。特殊命令でリフレッシュさせるか。)
* コンパイルまでのフェーズをオリジナルのS2から引き継ごう。
* resultの送信ラインを現在アクティブなchamberだけに絞る
* フィルタブロックもココに入る。

大きく分けて、

* Input
* CompileChamber
* Compile
* Abort
* Filtering
* Output