


var Pins=Object.freeze({
	ONLINE:0,
	P1_BTN:1,
	P2_BTN:2,
	P1_STAT:3,
	P2_STAT:4,
	P1_WINNER:5,
	P2_WINNER:6
});

var Connection=Object.freeze({
	OFFLINE:0,
	CONNECTING:1,
	ONLINE:2,
	DISABLED:3
});

connection.vars["P2_BTN"] = 6;
connection.vars["P2_STAT"] = 0;
connection.vars["P2_WINNER"] = 3;

var p1_curStat=0;
var p1_btn=6;
var p1_curWinner=3;

var btn_sent=false;

var online_disabled=true;

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
				}if(connection.vars["P2_BTN"] < 6){
					pico8_gpio[Pins.P2_BTN] = connection.vars["P2_BTN"];
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

		var p1_winner = pico8_gpio[Pins.P1_WINNER];
		if(p1_curWinner != p1_winner){
			p1_curWinner = p1_winner;
			connection.send("P2_WINNER",p1_curWinner);
		}

		//p2_curStat = Math.round(Math.random());
		pico8_gpio[Pins.P2_STAT] = connection.vars["P2_STAT"];
		pico8_gpio[Pins.P2_WINNER] = connection.vars["P2_WINNER"];
	}else{
		// not playing online
		if(connection.conn != null && connection.conn.peer != null){
			document.getElementById("p2_id").value = connection.conn.peer;
		}
	}

	window.requestAnimationFrame(poll);
}







document.getElementById("enable_online").addEventListener("click", function(){
	if(online_disabled){
		online_disabled=false;

		connection.onconnect=function(){
			pico8_gpio[Pins.ONLINE] = Connection.OFFLINE;
			connection.log("Connected to "+connection.conn.peer);
			document.getElementById("register").disabled=true;
			document.getElementById("connect").disabled=true;
		};

		document.getElementById("enable_online").style.display="none";
		document.getElementById("online_stuff").style.display="inline-block";
		document.getElementById("main").style.height="728px";

		document.getElementById("register").addEventListener("click", function(){
			document.getElementById("register").disabled=true;
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

			// if we lose
			connection.peer.on("disconnected",function(){
				connection.log("Disconnected from server.");
				document.getElementById("connect").disabled=true;
				document.getElementById("register").disabled=false;
			});
		});

		document.getElementById("connect").addEventListener("click",function(){
			if(connection.peer != null && !connection.peer.disconnected){
				var id=document.getElementById("p2_id").value;
				if(id != null && id != connection.p1_id){
					connection.connect(id);
				}else{
					connection.error("Error: Invalid opponent ID. (type: input)");
				}
			}else{
				connection.error("Error: No server connection detected. (type: runtime)");
				if(connection.peer != null && connection.peer.disconnected){
					connection.peer.reconnect();
					connection.log("Reconnecting...");
					document.getElementById("register").disabled=true;
				}
			}
		});

		poll();
	}
});
