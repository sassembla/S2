#S2'(えすつーだっしゅ)

**Super-Scala Compiler (改)**

##Basic Strategy:  
* ビルドは重労働なので非力なマシンで頑張らないほうが平和  
* どうせ最適化されるだろうから、今出来る最速をたたき出すための努力もそれを踏まえるべき  

**=>ビルドをリモートで非同期にガンガンやろう！**


Input部分の取り付けが終わったので、挙動を一通り移装しようと思う。

###基礎コンパイラ制御実装
* WebSocketのon-off周りが電源と一緒
* 接続してきたやつがいたら、ポジションを聞いてpullを行う(このへんはSRがやるべきことなので、イベントのキックだけをS2から行う。connected。)

* out ignited 起動完了、あとは羃的。listとかも結局pullに繋がるだけ、って感じで良いのでは。保存時にリストの更新ができればいいや。

* in listed 入力、リスト
* out pulling プル xN
* in pulled (chamber start) プルの完了(update内容に対するものなので、個別になる)xN =>内部ではupdateを使用。  
* in updated 入力、コード更新　
* out tick 今コンパイルしてますよイベントの送付(フィルタ有り、id有り)  

* in updated ..continue.

###テストの起動について
* 今はbuildタスクを使ってるからそのまま走るはず。
* テスト結果については、ビルドだけを行うチャンバーとテストだけを行うチャンバーに分けたいところ。

###保存時の処理
* コンパイル開始する
* in compile

###更新時の部分入力
* 部分入力をサポートするなら、in codeUpdatedで分岐、メモリ上の特定の位置に書き出す
* 同期する時の動作から、、ああ、めんどうくさい。置換もあるしな。pullしてしまおう。
* 部分入力無し2013/11/02 20:05:09

* in reset キャッシュしてるファイルのリセット要求
* out 

###tonedownの実装
* チャンバーの送信者としての寿命は、他のチャンバーが送ってきた場合は「もしかして」レベル、最新で後が無いものは「確定レベル」としてでる。
* 内容は、降格が発生するたびに、まず表示リセットがスタックされ、サーバ側からリフレッシュとして一気に送られてくる。

まず流すか。  
接続ラインの構築。フィルタは要らない、S2'側で出すものを選ぶ事にする。

* ST起動
* S2'起動
* SSで繋ぐ。client to server x2
* 



##S2PP spec　メモ

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

作業内容は大きく分けて、

* Input
* CompileChamber
* Compile
* Abort
* Filtering
* Output