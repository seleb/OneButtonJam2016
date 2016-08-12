


var Pins=Object.freeze({
	ONLINE:0,
	P1_BTN:1,
	P2_BTN:2,
	P1_STAT:3,
	P2_STAT:4
});

var Connection=Object.freeze({
	OFFLINE:0,
	CONNECTING:1,
	ONLINE:2,
	DISABLED:3
});

var p1_curStat=0;
var p2_curStat=0;
var p1_btn=6;
var p2_btn=6;

var btn_sent=false;



connection.handler["id"]=function(_val){
	connection.p2_id=_val;
};
connection.handler["P2_BTN"]=function(_val){
	p2_btn = _val;
};
connection.handler["P2_STAT"]=function(_val){
	p2_curStat = _val;
};


connection.log=function(_msg){
	document.getElementById("log").innerHTML+="<div>"+_msg+"</div>";
	document.getElementById("log").scrollTop = document.getElementById("log").scrollHeight;
}

connection.error=function(_msg){
	connection.log("<span style='color:#FF004d;'>"+_msg+"</span>");
}

function poll(){
	if(pico8_gpio[Pins.ONLINE] == Connection.CONNECTING){
		// connect to opponent
		
		if(connection == null){
			// try to connect
		}else{
			//send pico8_gpio[Pins.P1_BTN] as opponent's Pins.P2_BTN
			p1_btn = pico8_gpio[Pins.P1_BTN];

			if(connection.conn != null){
				if(!btn_sent && p1_btn != 6){
					btn_sent=true;
					connection.send("P2_BTN",pico8_gpio[Pins.P1_BTN]);
				}if(p2_btn != 6){
					pico8_gpio[Pins.P2_BTN] = p2_btn;
					pico8_gpio[Pins.ONLINE] = Connection.ONLINE;
				}
			}
		}
		// on connection
		//recieve pico8_gpio[Pins.P2_BTN]
	}else if(pico8_gpio[Pins.ONLINE] == Connection.ONLINE){
		// playing online
		var p1_stat = pico8_gpio[Pins.P1_STAT];
		if(p1_curStat != p1_stat){
			p1_curStat = p1_stat;

			connection.send("P2_STAT",p1_curStat);
		}

		//p2_curStat = Math.round(Math.random());
		pico8_gpio[Pins.P2_STAT] = p2_curStat;
	}else{
		// not playing online
	}

	window.requestAnimationFrame(poll);
}







document.getElementById("enable_online").addEventListener("click", function(){
	if(pico8_gpio[Pins.ONLINE] == Connection.DISABLED){
		pico8_gpio[Pins.ONLINE] = Connection.OFFLINE;

		document.getElementById("enable_online").style.display="none";
		document.getElementById("online_stuff").style.display="inline-block";
		document.getElementById("main").style.height="728px";

		document.getElementById("register").addEventListener("click", function(){
			connection.register(document.getElementById("p1_id").value);
			
			connection.peer.on("open", function(_id){
				connection.p1_id=_id;
				document.getElementById("p1_id").value = connection.p1_id;
				connection.log("Registered with ID "+connection.p1_id);

				document.getElementById("connect").disabled=false;
			});

			connection.peer.on("error", function(_err){
				connection.error(_err + " (type: "+_err.type+")");
			});

		});

		document.getElementById("connect").addEventListener("click",function(){
			if(connection.peer != null){
				var id=document.getElementById("p2_id").value;
				if(id != null && id != connection.p1_id){
					connection.connect(id);
				}else{
					connection.error("Error: Invalid opponent ID. (type: input)");
				}
			}else{
				connection.error("Error: No server connection detected. (type: runtime)");
			}
		});

		poll();
	}
});
