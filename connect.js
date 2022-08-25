var connection={
	peer:null,
	p1_id:null,
	p2_id:null,
	conn:null,
	vars:[],

	register:function(_id){
		this.p1_id = _id.toString();
		this.log("Registering "+_id+"...");
		this.peer = new Peer(this.p1_id, {
			host: "obd-connection-broker.glitch.me",
			port:443,
			secure:true,
			path:"/",
			debug:0
		});

		this.peer.on("connection", function(_conn){
			this.conn = _conn;
			this._onconnect();
		}.bind(this));
	},

	connect:function(_id){
		_id = (_id || "").toString().trim();
		if(_id.length > 0){
			this.log("Connecting to "+_id+"...");
			this.p2_id = _id;
			this.conn = this.peer.connect(this.p2_id);
			this.conn.on("open", function(){
				this._onconnect();
			}.bind(this));
		}else{
			this.error("Error: Invalid opponent ID.");
		}
	},

	send:function(_var, _val){
		this.conn.send('{"var":"'+_var+'","val":"'+_val+'"}');
	},

	log:function(_msg){
		console.log(_msg);
	},
	error:function(_msg){
		console.error(_msg);
	},

	onconnect:function(){
		// overwrite this
	},
	_onconnect:function(){
		this.onconnect();
		this.conn.on("data", function(data){
			var json=JSON.parse(data);
			console.log("received: " + data);
			this.vars[json.var] = json.val;
		}.bind(this));
	}
};
