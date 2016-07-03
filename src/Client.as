package cc.dy.model.net
{
   import flash.events.EventDispatcher;
   import flash.utils.Timer;
   import cc.dy.model.user.RoomUser;
   import util.$;
   import flash.utils.getTimer;
   import util.LocalStorage;
   import util.Util;
   import sample.loaderDanmu.CModule;
   import com.adobe.crypto.MD5;
   import com.adobe.crypto.HMAC;
   import flash.events.TimerEvent;
   import util.UserBehaviorLog;
   import common.event.EventCenter;
   import flash.events.Event;
   import flash.utils.clearTimeout;
   import flash.utils.setTimeout;
   import cc.dy.model.comment.CommentTime;
   import cc.dy.model.comment.SingleCommentData;
   import cc.dy.view.effect.ColorComentManager;
   import cc.dy.view.play.PlayMediator;
   
   public class Client
   {
      // base client to server, this is core. 
      public var _conn:cc.dy.model.net.TcpClient;
      
      public var barrage_Conn:cc.dy.model.net.ClientBarrage;
      
      public var dispatcher:EventDispatcher;
      
      public var my_uid:int;
      
      public var my_username:String;
      
      public var my_nickname:String;
      
      public var my_roomgroup:int;
      
      public var roomId:int;
      
      public var keep_online:int = 0;
      
      private var myTimer:Timer;
      
      private var cacheTimer:Timer;
      
      private var per_keep_live:int = 45;
      
      private var per_cachedata:int = 60;
      
      private var serialnum:int = 0;
      
      private var user_count:int = 0;
      
      public var users:Vector.<RoomUser>;
      
      public var admins:Vector.<RoomUser>;
      
      public var users100_sort:Vector.<RoomUser>;
      
      public var admins_sort:Vector.<RoomUser>;
      
      public var serverArray:Array;
      
      public var myblacklist:Array;
      
      private var _OnConn:Function;
      
      private var firstTime:Number;
      
      private var secondTime:Number;
      
      private var sendTime:Number;
      
      private var end2TimeIndex:uint;
      
      private var illNotifyIndex:uint;
      
      private var illCloseIndex:uint;
      
      private var endTimeIndex0:uint;
      
      private var endError:String;
      
      private var reloadTimeIndex:uint;
      
      private var randomValue:int;
      
      private var salt:String;
      
      private var endTimeIndex:uint;
      
      private var endStr:String;
      
      public function Client()
      {
         this.dispatcher = new EventDispatcher();
         this.users = new Vector.<RoomUser>();
         this.admins = new Vector.<RoomUser>();
         this.users100_sort = new Vector.<RoomUser>();
         this.admins_sort = new Vector.<RoomUser>();
         this.serverArray = new Array();
         this.myblacklist = new Array();
         super();
      }
      
      public function ConnectServer(param1:String, param2:int, param3:int, param4:Function) : void
      {
         $.jscall("console.log","string is [%s]","ConnectServer");
         this._conn = new cc.dy.model.net.TcpClient(GlobalData.isSecurError1);
         this._OnConn = param4;
         if(this._conn == null)
         {
            return;
         }
         this._conn.connect(param1,param2,param3);
         this._conn.addEventListener(TcpEvent.Conneted,param4,false,0,true);
         this._conn.addEventListener(TcpEvent.SecurityError,param4,false,0,true);
         this._conn.addEventListener(TcpEvent.Error,param4,false,0,true);
         this._conn.addEventListener(TcpEvent.Closed,param4,false,0,true);
         this._conn.addEventListener(TcpEvent.RecvMsg,this.ParseMsg,false,0,true);
      }
      
      public function UserLogin(param1:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         this.firstTime = getTimer();
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:String = _loc2_.GetItem("username");
         var _loc4_:String = _loc2_.GetItem("password");
         var _loc5_:int = _loc2_.GetItemAsInt("ct");
         var _loc6_:String = _loc2_.GetItem("ltkid");
         var _loc7_:String = _loc2_.GetItem("biz");
         var _loc8_:String = _loc2_.GetItem("stk");
         Param.clientType = _loc5_;
         this.roomId = _loc2_.GetItemAsInt("roomid");
         var _loc9_:Encode = new Encode();
         _loc9_.AddItem("type","loginreq");
         _loc9_.AddItem("username",_loc3_);
         _loc9_.AddItem("password",_loc4_);
         _loc9_.AddItem("roompass",Param.PASS_VERIFY);
         _loc9_.AddItem_int("roomid",this.roomId);
         LocalStorage.setValue("PmdSalt",_loc4_);
         var _loc10_:String = Util.getGuid();
         _loc9_.AddItem("devid",_loc10_);
         var _loc11_:Date = new Date();
         var _loc12_:int = _loc11_.time / 1000;
         var _loc13_:String = Util.getSecretStr(_loc12_ + "&" + _loc10_);
         _loc9_.AddItem("rt",_loc12_ + "");
         _loc9_.AddItem("vk",_loc13_);
         _loc9_.AddItem("ver",GlobalData.VERSION);
         _loc9_.AddItem_int("ct",_loc5_);
         var _loc14_:String = _loc9_.Get_SttString();
         var _loc15_:Encode = new Encode();
         _loc15_.AddItem("devid",_loc10_);
         _loc15_.AddItem("rt",_loc11_.time + "");
         var _loc16_:String = Util.getSecretStr(this.roomId + "&" + _loc10_ + _loc11_.time,"1");
         _loc15_.AddItem("adv",_loc16_);
         $.asTojs("room_dycookie_set","did",_loc10_,365 * 24 * 60 * 60);
         loaderDanmu.danmakuSetParameters(_loc3_,_loc4_,_loc10_,_loc6_,_loc7_,_loc8_,this.roomId,_loc5_,0,GlobalData.VERSION);
         var _loc17_:int = CModule.malloc(4);
         var _loc18_:int = loaderDanmu.getAdVerificationData(_loc11_.time,_loc17_);
         var _loc19_:int = CModule.read32(_loc17_);
         $.asTojs("room_data_getdid",CModule.readString(_loc19_,_loc18_));
         loaderDanmu.danmakuFreeData(_loc17_);
         CModule.free(_loc17_);
         var _loc20_:int = CModule.malloc(4);
         var _loc21_:int = loaderDanmu.danmakuGetLoginRoomData(_loc12_,_loc20_);
         var _loc22_:int = CModule.read32(_loc20_);
         var _loc23_:String = CModule.readString(_loc22_,_loc21_);
         $.jscall("console.log","urlgreq is [%s]",_loc23_);
         this._conn.sendmsg(_loc23_);
         loaderDanmu.danmakuFreeData(_loc20_);
         CModule.free(_loc20_);
      }
      
      public function verRequest(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:String = _loc2_.GetItem("username");
         var _loc4_:String = _loc2_.GetItem("nickname");
         var _loc5_:Encode = new Encode();
         _loc5_.AddItem("type","lvrq");
         _loc5_.AddItem("u",_loc3_);
         _loc5_.AddItem("n",_loc4_);
         _loc5_.AddItem("v",GlobalData.VERSION);
         if(this._conn == null)
         {
            return;
         }
         this._conn.sendmsg(_loc5_.Get_SttString());
         $.jscall("console.log","versionreq is [%s]",_loc5_.Get_SttString());
      }
      
      public function anotherUserLogin(param1:String) : void
      {
         var _loc2_:String = "";
         var _loc3_:Encode = new Encode();
         _loc3_.AddItem("type","hp");
         var _loc4_:String = LocalStorage.getValue("PmdSalt","");
         if(_loc4_ == "")
         {
            _loc2_ = LocalStorage.getValue("PassSalt","");
         }
         else
         {
            _loc2_ = MD5.hash(_loc4_ + this.salt);
         }
         var _loc5_:String = HMAC.hash(this.randomValue.toString(),_loc2_);
         _loc3_.AddItem("password",_loc5_);
         $.jscall("console.log","req is ");
         if(this._conn == null)
         {
            return;
         }
         this._conn.sendmsg(_loc3_.Get_SttString());
      }
      
      public function UserLogout() : void
      {
         $.jscall("console.log","urlo[%s]",1111);
         var _loc1_:Encode = new Encode();
         _loc1_.AddItem("type","logout");
         var _loc2_:String = _loc1_.Get_SttString();
         if(this._conn != null)
         {
            this._conn.sendmsg(_loc2_);
         }
         this.clean_conn_timer();
      }
      
      public function SendChatContent(param1:String) : void
      {
         var _loc8_:Encode = null;
         var _loc9_:String = null;
         var _loc10_:Encode = null;
         var _loc11_:String = null;
         $.jscall("console.log","jscc[%s]",param1);
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("sender");
         var _loc4_:int = _loc2_.GetItemAsInt("receiver");
         var _loc5_:String = _loc2_.GetItem("content");
         var _loc6_:String = _loc2_.GetItem("scope");
         var _loc7_:int = _loc2_.GetItemAsInt("col");
         if(!this.black_word(_loc5_))
         {
            _loc8_ = new Encode();
            _loc8_.AddItem("type","chatmessage");
            _loc8_.AddItem_int("receiver",_loc4_);
            _loc8_.AddItem("content",_loc5_);
            _loc8_.AddItem("scope",_loc6_);
            _loc8_.AddItem_int("col",_loc7_);
            _loc9_ = _loc8_.Get_SttString();
            $.jscall("console.log","scc[%s]",_loc9_);
            if(this._conn == null)
            {
               return;
            }
            if(this.my_uid == 4257531)
            {
               $.jscall("console.log","4257531 sendmsgtime=………………" + new Date().time / 1000);
            }
            this.sendTime = new Date().time;
            this._conn.sendmsg(_loc9_);
         }
         else
         {
            _loc10_ = new Encode();
            _loc10_.AddItem("type","error");
            _loc10_.AddItem_int("code",60);
            _loc11_ = _loc10_.Get_SttString();
            $.jscall("console.log","server_error [%s]",_loc11_);
            $.asTojs("room_data_sererr",_loc11_);
         }
      }
      
      public function KeepLive(param1:TimerEvent = null) : void
      {
         var _loc2_:Encode = null;
         var _loc3_:Date = null;
         var _loc4_:int = 0;
         var _loc5_:String = null;
         var _loc6_:String = null;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         if(this._conn != null)
         {
            _loc2_ = new Encode();
            _loc2_.AddItem("type","keeplive");
            _loc3_ = new Date();
            _loc4_ = _loc3_.time / 1000;
            _loc5_ = Util.getSecretStr(_loc4_ + "&" + GlobalData.byteCount,"3");
            _loc2_.AddItem_int("tick",_loc4_);
            _loc2_.AddItem_int("vbw",GlobalData.byteCount);
            _loc2_.AddItem_int("cdn",GlobalData.CDNType);
            _loc2_.AddItem("k",_loc5_);
            _loc6_ = _loc2_.Get_SttString();
            _loc7_ = CModule.malloc(4);
            _loc8_ = loaderDanmu.danmakuGetKeepLiveData(_loc4_,GlobalData.byteCount,_loc7_);
            _loc9_ = CModule.read32(_loc7_);
            this._conn.sendmsg(CModule.readString(_loc9_,_loc8_));
            loaderDanmu.danmakuFreeData(_loc7_);
            CModule.free(_loc7_);
            $.jscall("console.log","time=" + getTimer());
         }
      }
      
      public function RoomRefresh(param1:TimerEvent) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc2_:Encode = new Encode();
         _loc2_.AddItem("type","roomrefresh");
         _loc2_.AddItem_int("serialnum",this.serialnum);
         var _loc3_:String = _loc2_.Get_SttString();
         this._conn.sendmsg(_loc3_);
      }
      
      public function SetAdmin(param1:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("userid");
         var _loc4_:int = _loc2_.GetItemAsInt("group");
         var _loc5_:Encode = new Encode();
         _loc5_.AddItem("type","setadminreq");
         _loc5_.AddItem_int("userid",_loc3_);
         _loc5_.AddItem_int("group",_loc4_);
         var _loc6_:String = _loc5_.Get_SttString();
         this._conn.sendmsg(_loc6_);
      }
      
      public function BlackUser(param1:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         $.jscall("console.log","js_BlackUser [%s]",param1);
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("userid");
         var _loc4_:int = _loc2_.GetItemAsInt("blacktype");
         var _loc5_:int = _loc2_.GetItemAsInt("limittime");
         var _loc6_:Encode = new Encode();
         _loc6_.AddItem("type","blackreq");
         _loc6_.AddItem_int("userid",_loc3_);
         _loc6_.AddItem_int("blacktype",_loc4_);
         _loc6_.AddItem_int("limittime",_loc5_);
         var _loc7_:String = _loc6_.Get_SttString();
         this._conn.sendmsg(param1);
      }
      
      public function SendByteCount(param1:Number) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc2_:Encode = new Encode();
         _loc2_.AddItem("type","vbwr");
         _loc2_.AddItem_int("vbw",param1);
         _loc2_.AddItem_int("rid",this.roomId);
         var _loc3_:String = _loc2_.Get_SttString();
         this._conn.sendmsg(_loc3_);
      }
      
      public function SendEmptyOrFullCount(param1:int, param2:int, param3:int, param4:String, param5:int, param6:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc7_:Encode = new Encode();
         _loc7_.AddItem("type","ssr");
         _loc7_.AddItem_int("uid",Param.uid);
         _loc7_.AddItem_int("rid",int(Param.RoomId));
         _loc7_.AddItem_int("ec",param2);
         _loc7_.AddItem("surl",param4);
         _loc7_.AddItem("cdn",Param.CDN);
         _loc7_.AddItem_int("isp2p",param5);
         var _loc8_:String = Util.getGuid();
         _loc7_.AddItem("did",_loc8_);
         _loc7_.AddItem_int("ps",param1);
         _loc7_.AddItem_int("ct",Param.clientType);
         if(param1 == 3)
         {
            _loc7_.AddItem("ext",param6);
         }
         var _loc9_:String = _loc7_.Get_SttString();
         this._conn.sendmsg(_loc9_);
      }
      
      public function MyBlackList(param1:String) : void
      {
         this.myblacklist = param1.split("|");
         $.jscall("console.log","handIn_blacklist [%s]",param1);
      }
      
      public function givePresent(param1:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("mg");
         var _loc4_:int = _loc2_.GetItemAsInt("ms");
         var _loc5_:Encode = new Encode();
         _loc5_.AddItem("type","donatereq");
         _loc5_.AddItem_int("mg",_loc3_);
         _loc5_.AddItem_int("ms",_loc4_);
         var _loc6_:String = _loc5_.Get_SttString();
         this._conn.sendmsg(_loc6_);
         $.jscall("console.log","赠送鱼丸请求");
      }
      
      public function giveGift(param1:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("gfid");
         var _loc4_:int = _loc2_.GetItemAsInt("num");
         var _loc5_:int = _loc2_.GetItemAsInt("bat");
         var _loc6_:Encode = new Encode();
         _loc6_.AddItem("type","sgq");
         _loc6_.AddItem_int("gfid",_loc3_);
         _loc6_.AddItem_int("num",_loc4_);
         var _loc7_:String = _loc6_.Get_SttString();
         var _loc8_:int = CModule.malloc(4);
         var _loc9_:int = loaderDanmu.danmakuGetSendYuwanData(String(_loc3_),_loc4_,_loc5_,_loc8_);
         var _loc10_:int = CModule.read32(_loc8_);
         this._conn.sendmsg(CModule.readString(_loc10_,_loc9_));
         loaderDanmu.danmakuFreeData(_loc8_);
         CModule.free(_loc8_);
         $.jscall("console.log","zsgreq");
      }
      
      public function queryTask() : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc1_:Encode = new Encode();
         _loc1_.AddItem("type","qtlq");
         var _loc2_:String = _loc1_.Get_SttString();
         this._conn.sendmsg(_loc2_);
         $.jscall("console.log","qtq2");
      }
      
      public function queryTaskNum() : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc1_:Encode = new Encode();
         _loc1_.AddItem("type","qtlnq");
         var _loc2_:String = _loc1_.Get_SttString();
         this._conn.sendmsg(_loc2_);
         $.jscall("console.log","qtq1");
      }
      
      public function obtainTask(param1:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("tid");
         var _loc4_:Encode = new Encode();
         _loc4_.AddItem("type","gftq");
         _loc4_.AddItem_int("tid",_loc3_);
         var _loc5_:String = _loc4_.Get_SttString();
         this._conn.sendmsg(_loc5_);
         $.jscall("console.log","领取任务请求");
      }
      
      public function setKeytitles(param1:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("userid");
         var _loc4_:String = _loc2_.GetItem("username");
         var _loc5_:String = _loc2_.GetItem("reason");
         var _loc6_:String = _loc2_.GetItem("limittime");
         var _loc7_:Encode = new Encode();
         _loc7_.AddItem("type","gbm");
         _loc7_.AddItem_int("uid",_loc3_);
         _loc7_.AddItem_int("rid",this.roomId);
         _loc7_.AddItem("uname",_loc4_);
         _loc7_.AddItem("reason",_loc5_);
         _loc7_.AddItem("limittime",_loc6_);
         var _loc8_:String = _loc7_.Get_SttString();
         this._conn.sendmsg(_loc8_);
         $.jscall("console.log","keytitle =userid" + _loc3_ + "   uname=" + _loc4_ + "  reason=" + _loc5_ + " roomId=" + this.roomId);
      }
      
      public function setReportBarrage(param1:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("suid");
         var _loc4_:int = _loc2_.GetItemAsInt("rid");
         var _loc5_:String = _loc2_.GetItem("chatmsgid");
         var _loc6_:int = _loc2_.GetItemAsInt("rept");
         var _loc7_:Encode = new Encode();
         _loc7_.AddItem("type","chatmsgrep");
         _loc7_.AddItem_int("suid",_loc3_);
         _loc7_.AddItem_int("rid",_loc4_);
         if(_loc6_ == 0)
         {
            _loc7_.AddItem("chatmsgid",_loc5_);
         }
         _loc7_.AddItem_int("rept",_loc6_);
         var _loc8_:String = _loc7_.Get_SttString();
         this._conn.sendmsg(_loc8_);
      }
      
      public function requestRewardList() : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc1_:Encode = new Encode();
         _loc1_.AddItem("type","qrl");
         _loc1_.AddItem("rid",Param.RoomId);
         var _loc2_:String = _loc1_.Get_SttString();
         var _loc3_:int = CModule.malloc(4);
         var _loc4_:int = loaderDanmu.danmakuGetRankListData(int(Param.RoomId),Param.isShow == 1?1:0,_loc3_);
         var _loc5_:int = CModule.read32(_loc3_);
         this._conn.sendmsg(CModule.readString(_loc5_,_loc4_));
         loaderDanmu.danmakuFreeData(_loc3_);
         CModule.free(_loc3_);
         $.jscall("console.log","酬勤榜单请求");
      }
      
      public function emailNotifyResponse(param1:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:String = _loc2_.GetItem("mid");
         var _loc4_:Encode = new Encode();
         _loc4_.AddItem("type","mailnewres");
         _loc4_.AddItem("mid",_loc3_);
         var _loc5_:String = _loc4_.Get_SttString();
         this._conn.sendmsg(_loc5_);
         $.jscall("console.log","私信回执 ");
      }
      
      public function queryGiftPkg(param1:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         this._conn.sendmsg(param1);
         $.jscall("console.log","查询礼包信息 =" + param1);
      }
      
      public function dmodelNotify(param1:int) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc2_:Encode = new Encode();
         _loc2_.AddItem("type","jfdg");
         _loc2_.AddItem_int("op",param1);
         var _loc3_:String = _loc2_.Get_SttString();
         this._conn.sendmsg(_loc3_);
         $.jscall("console.log","dmcnotify");
      }
      
      public function superDanmuClickReq(param1:Object) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc2_:Encode = new Encode();
         _loc2_.AddItem("type","sdcr");
         _loc2_.AddItem_int("rid",param1.crid);
         _loc2_.AddItem_int("sdid",param1.did);
         _loc2_.AddItem_int("trid",param1.nrid);
         _loc2_.AddItem_int("uid",this.my_uid);
         _loc2_.AddItem("content",param1.supercontent);
         var _loc3_:String = Util.getGuid();
         _loc2_.AddItem("did",_loc3_);
         var _loc4_:String = _loc2_.Get_SttString();
         this._conn.sendmsg(_loc4_);
         $.jscall("console.log","sdmcount");
      }
      
      public function jsSuperDanmuClickReq(param1:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("sdid");
         var _loc4_:int = _loc2_.GetItemAsInt("trid");
         var _loc5_:String = _loc2_.GetItem("content");
         var _loc6_:int = _loc2_.GetItemAsInt("rid");
         var _loc7_:int = _loc2_.GetItemAsInt("uid");
         var _loc8_:Encode = new Encode();
         _loc8_.AddItem("type","sdcr");
         _loc8_.AddItem_int("rid",_loc6_);
         _loc8_.AddItem_int("sdid",_loc3_);
         _loc8_.AddItem_int("trid",_loc4_);
         _loc8_.AddItem_int("uid",this.my_uid);
         _loc8_.AddItem("content",_loc5_);
         var _loc9_:String = Util.getGuid();
         _loc8_.AddItem("did",_loc9_);
         var _loc10_:String = _loc8_.Get_SttString();
         this._conn.sendmsg(_loc10_);
         $.jscall("console.log","sdmcount1");
      }
      
      public function hbRequest(param1:String) : void
      {
         if(this._conn == null)
         {
            return;
         }
         this._conn.sendmsg(param1);
         $.jscall("console.log","hbq：" + param1);
      }
      
      public function roomSignUp() : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc1_:Encode = new Encode();
         _loc1_.AddItem("type","signinq");
         var _loc2_:String = _loc1_.Get_SttString();
         this._conn.sendmsg(_loc2_);
         $.jscall("console.log","房间签到请求");
      }
      
      public function shareSuccess(param1:Number) : void
      {
         if(this._conn == null || Param.isLoginUser == 0)
         {
            return;
         }
         var _loc2_:Encode = new Encode();
         _loc2_.AddItem("type","srreq");
         _loc2_.AddItem_int("rid",this.roomId);
         _loc2_.AddItem_int("uid",this.my_uid);
         _loc2_.AddItem("nickname",this.my_nickname);
         _loc2_.AddItem_int("exp",param1);
         this._conn.sendmsg(_loc2_.Get_SttString());
         $.jscall("console.log","share request");
      }
      
      private function ParseMsg(param1:TcpEvent) : void
      {
         var _loc5_:Number = NaN;
         var _loc6_:int = 0;
         var _loc2_:String = param1._param as String;
         var _loc3_:Decode = new Decode();
         _loc3_.Parse(_loc2_);
         var _loc4_:String = _loc3_.GetItem("type");
         if(_loc4_ != "keeplive" && _loc4_ != "chatmessage" && _loc4_ != "chatmsg")
         {
            $.jscall("console.log","网络数据 [%s]",_loc2_);
         }
         if(_loc4_ == "loginres")
         {
            this.secondTime = getTimer();
            _loc5_ = this.secondTime - this.firstTime;
            if(_loc5_ >= 2000)
            {
               _loc6_ = new Date().time / 1000;
               UserBehaviorLog.getInstance().sendChatLog(UserBehaviorLog.POINT_ID_LOGIN_SERVER,_loc6_,{
                  "id":Param.ServerIp + ":" + Param.ServerPort,
                  "lag":_loc5_
               });
            }
            this.ServerLoginInfo(_loc2_);
            this.reqOnlineGift();
            this.KeepLive();
            EventCenter.dispatch("login",{"code":0});
         }
         else if(_loc4_ == "sui")
         {
            this.ServerUserInfoContent(_loc3_);
         }
         else if(_loc4_ == "chatmessage")
         {
            this.ServerChatContent(_loc3_);
         }
         else if(_loc4_ == "keeplive")
         {
            this.ServerKeepLive(_loc3_);
         }
         else if(_loc4_ == "setadminres")
         {
            this.ServerSetAdmin(_loc2_);
         }
         else if(_loc4_ == "blackres")
         {
            this.ServerBlackUser(_loc3_);
         }
         else if(_loc4_ == "roomrefresh")
         {
            this.ServerRoomRefresh(_loc3_);
         }
         else if(_loc4_ == "error")
         {
            this.ServerError(_loc3_);
         }
         else if(_loc4_ == "rss")
         {
            this.ServerShowStatus(_loc3_);
         }
         else if(_loc4_ == "msgrepeaterlist")
         {
            this.ServerRepeaterlist(_loc3_);
         }
         else if(_loc4_ == "setmsggroup")
         {
            this.ServerSetGroup(_loc3_);
         }
         else if(_loc4_ == "joingroup")
         {
            this.ServerJoinGroup(_loc3_);
         }
         else if(_loc4_ == "rsm")
         {
            this.systemBroadcast(_loc2_);
         }
         else if(_loc4_ == "donateres")
         {
            this.fishPresent(_loc2_);
         }
         else if(_loc4_ == "qtlr")
         {
            this.taskList(_loc2_);
         }
         else if(_loc4_ == "qtlnr")
         {
            this.taskNum(_loc2_);
         }
         else if(_loc4_ == "gftr")
         {
            this.obtainTaskRes(_loc2_);
         }
         else if(_loc4_ == "signinr")
         {
            this.roomSignUpRes(_loc2_);
         }
         else if(_loc4_ == "resog")
         {
            this.onlineGiftRes(_loc3_);
         }
         else if(_loc4_ == "gbmres")
         {
            this.keyTitlesRes(_loc2_);
         }
         else if(_loc4_ != "rdr")
         {
            if(_loc4_ != "scl")
            {
               if(_loc4_ == "common_call")
               {
                  this.baoXuetime(_loc2_);
               }
               else if(_loc4_ == "chatmsgrep")
               {
                  this.reportBarrage(_loc2_);
               }
               else if(_loc4_ == "adminnotify")
               {
                  this.identityChange(_loc3_);
               }
               else if(_loc4_ == "ranklist")
               {
                  this.rewardListResponse(_loc2_);
               }
               else if(_loc4_ == "mailnewreq")
               {
                  this.emailNotify(_loc2_);
               }
               else if(_loc4_ == "gb")
               {
                  this.updateYC(_loc2_);
               }
               else if(_loc4_ == "memberinfores")
               {
                  this.roomInfoRes(_loc2_);
               }
               else if(_loc4_ == "qgpi_rsp")
               {
                  this.giftPkgRes(_loc2_);
               }
               else if(_loc4_ == "dsgr")
               {
                  this.giveFishBallres(_loc2_);
               }
               else if(_loc4_ == "refresh_flash")
               {
                  this.reloadStreamNotify();
               }
               else if(_loc4_ == "ggbr")
               {
                  this.hbGetResponse(_loc2_);
               }
               else if(_loc4_ == "lvrs")
               {
                  this.verResponse(_loc3_);
               }
               else if(_loc4_ == "saltr")
               {
                  this.randomStrResponse(_loc3_);
               }
               else if(_loc4_ == "chatmsg")
               {
                  this.newServerChatContent(_loc2_);
               }
               else if(_loc4_ == "chatres")
               {
                  this.newChatRes(_loc2_);
               }
               else if(_loc4_ == "expnt")
               {
                  this.expUpdate(_loc2_);
               }
               else if(_loc4_ == "notify_cgap")
               {
                  this.gapNotify(_loc2_);
               }
               else if(_loc4_ == "initcl")
               {
                  this.initChatLimit(_loc2_);
               }
               else if(_loc4_ == "pet_info")
               {
                  this.christmasTree(_loc2_);
               }
               else if(_loc4_ == "bcrp")
               {
                  this.petInfo(_loc2_);
               }
               else if(_loc4_ == "user_pets")
               {
                  this.petReceived(_loc2_);
               }
               else if(_loc4_ == "alipayblackres")
               {
                  this.alipayblackres(_loc3_);
               }
               else if(_loc4_ == "newblackres")
               {
                  this.room_data_sys(_loc2_);
               }
               else if(_loc4_ == "ntmet")
               {
                  this.room_data_sys(_loc2_);
               }
               else if(_loc4_ == "ncrmc")
               {
                  this.room_data_sys(_loc2_);
               }
               else if(_loc4_ == "muteinfo")
               {
                  this.room_data_sys(_loc2_);
               }
               else if(_loc4_ == "bdgo")
               {
                  this.room_data_giftbat1(_loc2_);
               }
            }
         }
      }
      
      private function ServerLoginInfo(param1:String) : void
      {
         var randTime:int = 0;
         var str:String = param1;
         var _strdecode:Decode = new Decode();
         _strdecode.Parse(str);
         var type:String = _strdecode.GetItem("type");
         var userid:int = _strdecode.GetItemAsInt("userid");
         var username:String = _strdecode.GetItem("username");
         var nickname:String = _strdecode.GetItem("nickname");
         var roomgroup:int = _strdecode.GetItemAsInt("roomgroup");
         var sessionid:int = _strdecode.GetItemAsInt("sessionid");
         var pg:int = _strdecode.GetItemAsInt("pg");
         var live_stat:int = _strdecode.GetItemAsInt("live_stat");
         var npv:int = _strdecode.GetItemAsInt("npv");
         var ps:int = _strdecode.GetItemAsInt("ps");
         var es:int = _strdecode.GetItemAsInt("es");
         var best_dlev:int = _strdecode.GetItemAsInt("best_dlev");
         var cur_lev:int = _strdecode.GetItemAsInt("cur_lev");
         var is_illegal:int = _strdecode.GetItemAsInt("is_illegal");
         var illegal_warning_content:String = _strdecode.GetItem("ill_ct");
         var illegal_timestamp:Number = _strdecode.GetItemAsNumber("ill_ts");
         var now:Number = _strdecode.GetItemAsNumber("now");
         var nrc:int = _strdecode.GetItemAsInt("nrc");
         var it:int = _strdecode.GetItemAsInt("it");
         var its:int = _strdecode.GetItemAsInt("its");
         var bdg:String = _strdecode.GetItem("bdg");
         Param.isPs = npv;
         if(live_stat == 0 && (Boolean(Param.Status) || Param.IS_HOSTLIVE == 1 || Param.usergroupid == "5"))
         {
            if(Param.IS_HOSTLIVE == 1 || Param.usergroupid == "5")
            {
               $.jscall("console.log","ServerShowStatus0 =" + 0);
               this.dispatcher.dispatchEvent(new Event("ServerShowStatus"));
               $.asTojs("room_bus_clswatchtip");
            }
            else
            {
               clearTimeout(this.end2TimeIndex);
               randTime = int(Math.random() * 30);
               $.jscall("console.log","ServerShowStatus0 =" + randTime);
               this.end2TimeIndex = setTimeout(function():void
               {
                  dispatcher.dispatchEvent(new Event("ServerShowStatus"));
                  $.asTojs("room_bus_clswatchtip");
               },randTime * 1000);
            }
         }
         if((nrc & 2) != 0)
         {
            EventCenter.dispatch("PwdNotifyEvent",{"type":1});
         }
         this.my_uid = userid;
         Param.uid = userid;
         Param.userId = this.my_uid.toString();
         this.my_username = username;
         this.my_nickname = nickname;
         this.my_roomgroup = roomgroup;
         GlobalData.isYouke = this.my_roomgroup;
         GlobalData.rg = roomgroup;
         GlobalData.pg = pg;
         if(GlobalData.isYouke == 0)
         {
            Param.userId = "0";
         }
         var _strencode:Encode = new Encode();
         _strencode.AddItem("type",type);
         _strencode.AddItem_int("userid",userid);
         _strencode.AddItem("nickname",nickname);
         _strencode.AddItem_int("roomgroup",this.my_roomgroup);
         _strencode.AddItem_int("pg",pg);
         _strencode.AddItem_int("best_dlev",best_dlev);
         _strencode.AddItem_int("cur_lev",cur_lev);
         _strencode.AddItem_int("is_illegal",is_illegal);
         _strencode.AddItem("ill_ct",illegal_warning_content);
         _strencode.AddItem_int("ill_ts",illegal_timestamp);
         _strencode.AddItem_int("now",now);
         _strencode.AddItem_int("ps",ps);
         _strencode.AddItem_int("es",es);
         _strencode.AddItem_int("nrc",nrc);
         _strencode.AddItem_int("it",it);
         _strencode.AddItem_int("its",its);
         _strencode.AddItem_int("npv",npv);
         _strencode.AddItem("bdg",bdg);
         var loginres:String = _strencode.Get_SttString();
         $.jscall("console.log","isYouke =" + GlobalData.isYouke + "   live_stat =" + live_stat + "   roomgroup =" + roomgroup + " npv =" + npv + "&& return_tourist",loginres);
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_login",loginres);
         }
         else
         {
            $.asTojs("room_data_login",str);
         }
         if(this.myTimer == null)
         {
            this.myTimer = new Timer(this.per_keep_live * 1000,0);
            this.myTimer.addEventListener(TimerEvent.TIMER,this.KeepLive,false,0,true);
            this.myTimer.start();
         }
         else
         {
            this.myTimer.reset();
            this.myTimer.start();
         }
         EventCenter.dispatch("userRGEvent",null);
         if(is_illegal == 1)
         {
            Util.dispatchIllegal(1,now - illegal_timestamp);
         }
      }
      
      public function reqOnlineGift() : void
      {
         var _loc1_:Encode = null;
         var _loc2_:String = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         if(this._conn == null)
         {
            return;
         }
         if(GlobalData.isYouke != 0)
         {
            _loc1_ = new Encode();
            _loc1_.AddItem("type","reqog");
            _loc1_.AddItem_int("uid",this.my_uid);
            _loc2_ = _loc1_.Get_SttString();
            _loc3_ = CModule.malloc(4);
            _loc4_ = loaderDanmu.danmakuGetTaskTimeData(this.my_uid,_loc3_);
            _loc5_ = CModule.read32(_loc3_);
            this._conn.sendmsg(CModule.readString(_loc5_,_loc4_));
            loaderDanmu.danmakuFreeData(_loc3_);
            CModule.free(_loc3_);
            $.jscall("console.log","在线宝箱请求 ");
         }
      }
      
      private function presonalInfoReq() : void
      {
         if(this._conn == null)
         {
            return;
         }
         var _loc1_:Encode = new Encode();
         _loc1_.AddItem("type","memberinforeq");
         _loc1_.AddItem("link",GlobalData.domainName);
         var _loc2_:String = _loc1_.Get_SttString();
         this._conn.sendmsg(_loc2_);
         $.jscall("console.log","ifrq ");
      }
      
      private function ServerUserInfoContent(param1:Decode) : void
      {
         var _loc2_:String = param1.GetItem("sui");
         var _loc3_:Decode = new Decode();
         _loc3_.Parse(_loc2_);
         var _loc4_:int = _loc3_.GetItemAsInt("id");
         var _loc5_:String = _loc3_.GetItem("name");
         var _loc6_:String = _loc3_.GetItem("nick");
         var _loc7_:int = _loc3_.GetItemAsInt("rg");
         var _loc8_:int = _loc3_.GetItemAsInt("bg");
         var _loc9_:int = _loc3_.GetItemAsInt("pg");
         var _loc10_:int = _loc3_.GetItemAsInt("rt");
         var _loc11_:Number = _loc3_.GetItemAsNumber("weight");
         var _loc12_:Number = _loc3_.GetItemAsNumber("strength");
         var _loc13_:int = _loc3_.GetItemAsInt("cps_id");
      }
      
      private function ServerChatContent(param1:Decode) : void
      {
         var _loc27_:Encode = null;
         var _loc28_:String = null;
         var _loc29_:String = null;
         var _loc30_:String = null;
         var _loc31_:Boolean = false;
         var _loc32_:Number = NaN;
         var _loc33_:int = 0;
         var _loc34_:int = 0;
         var _loc35_:Encode = null;
         var _loc2_:int = param1.GetItemAsInt("rescode");
         var _loc3_:int = param1.GetItemAsInt("time");
         var _loc4_:int = param1.GetItemAsInt("sender");
         var _loc5_:int = param1.GetItemAsInt("receiver");
         var _loc6_:String = param1.GetItem("content");
         var _loc7_:String = param1.GetItem("scope");
         var _loc8_:String = param1.GetItem("snick");
         var _loc9_:String = param1.GetItem("dnick");
         var _loc10_:int = param1.GetItemAsInt("cd");
         var _loc11_:String = param1.GetItem("sui");
         var _loc12_:String = param1.GetItem("chatmsgid");
         var _loc13_:int = param1.GetItemAsInt("maxl");
         var _loc14_:int = param1.GetItemAsInt("col");
         var _loc15_:int = param1.GetItemAsInt("ct");
         GlobalData.chatMaxChars = _loc13_;
         var _loc16_:Decode = new Decode();
         _loc16_.Parse(_loc11_);
         var _loc17_:int = _loc16_.GetItemAsInt("rg");
         var _loc18_:int = _loc16_.GetItemAsInt("pg");
         var _loc19_:int = _loc16_.GetItemAsInt("m_deserve_lev");
         var _loc20_:int = _loc16_.GetItemAsInt("cq_cnt");
         var _loc21_:int = _loc16_.GetItemAsInt("best_dlev");
         var _loc22_:int = _loc16_.GetItemAsInt("level");
         var _loc23_:int = _loc16_.GetItemAsInt("gt");
         var _loc24_:String = _loc16_.GetItem("shark");
         var _loc25_:int = _loc16_.GetItemAsInt("naat");
         var _loc26_:int = _loc16_.GetItemAsInt("nrt");
         if(_loc2_ == 0)
         {
            _loc27_ = new Encode();
            _loc27_.AddItem("type","chatmessage");
            _loc27_.AddItem_int("rescode",_loc2_);
            if(_loc4_)
            {
               _loc27_.AddItem("sender_nickname",_loc8_);
               _loc27_.AddItem_int("sender",_loc4_);
            }
            else
            {
               _loc27_.AddItem_int("sender",_loc4_);
            }
            _loc27_.AddItem_int("receiver",_loc5_);
            if(_loc5_ != 0)
            {
               _loc27_.AddItem("receiver_nickname",_loc9_);
            }
            else
            {
               _loc27_.AddItem("receiver_nickname","");
            }
            _loc27_.AddItem("content",_loc6_);
            _loc27_.AddItem_int("roomgroup",1);
            _loc27_.AddItem_int("cd",_loc10_);
            _loc27_.AddItem_int("sender_rg",_loc17_);
            _loc27_.AddItem_int("sender_pg",_loc18_);
            if(_loc7_ == "private")
            {
               _loc27_.AddItem("chatmsgid",_loc12_);
               _loc28_ = _loc27_.Get_SttString();
               $.asTojs("room_data_chatpri",_loc28_);
            }
            else
            {
               _loc27_.AddItem_int("time",_loc3_);
               _loc27_.AddItem_int("maxl",_loc13_);
               _loc27_.AddItem_int("m_deserve_lev",_loc19_);
               _loc27_.AddItem("chatmsgid",_loc12_);
               _loc27_.AddItem_int("cq_cnt",_loc20_);
               _loc27_.AddItem_int("col",_loc14_);
               _loc27_.AddItem_int("ct",_loc15_);
               _loc27_.AddItem_int("best_dlev",_loc21_);
               _loc27_.AddItem_int("level",_loc22_);
               _loc27_.AddItem_int("gt",_loc23_);
               _loc27_.AddItem("shark",_loc24_);
               _loc27_.AddItem_int("naat",_loc25_);
               _loc27_.AddItem_int("nrt",_loc26_);
               _loc29_ = _loc27_.Get_SttString();
               $.asTojs("room_data_chat",_loc29_);
               if(this.myblacklist.indexOf(_loc4_.toString()) == -1)
               {
                  _loc30_ = Util.facereplace(_loc6_);
                  if(_loc30_ != "")
                  {
                     _loc31_ = _loc4_ == this.my_uid?true:false;
                     if(_loc31_)
                     {
                        _loc32_ = new Date().time;
                        _loc33_ = _loc32_ - this.sendTime;
                        if(_loc33_ >= 1000)
                        {
                           _loc34_ = this.sendTime / 1000;
                           UserBehaviorLog.getInstance().sendChatLog(UserBehaviorLog.POINT_ID_CHAT_DELAY,_loc34_,{
                              "id":this.barrage_Conn.ip + ":" + this.barrage_Conn.port,
                              "lag":_loc33_
                           });
                        }
                     }
                     if(_loc14_ == 0)
                     {
                        CommentTime.instance.start(new SingleCommentData(_loc30_,Util.getColor(_loc14_),GlobalData.textSizeValue,getTimer(),_loc31_,GlobalData.danmuModel));
                     }
                     else
                     {
                        ColorComentManager.instance.addColorData({
                           "type":_loc14_,
                           "sender":_loc8_,
                           "content":_loc30_
                        });
                     }
                  }
               }
            }
         }
         else if(_loc2_ == 289 || _loc2_ == 290 || _loc2_ == 294 || _loc2_ == 363)
         {
            _loc35_ = new Encode();
            _loc35_.AddItem("type","chatmessage");
            _loc35_.AddItem_int("rescode",_loc2_);
            if(_loc4_)
            {
               _loc35_.AddItem("sender_nickname",_loc8_);
               _loc35_.AddItem_int("sender",_loc4_);
            }
            else
            {
               _loc35_.AddItem_int("sender",_loc4_);
            }
            $.asTojs("room_data_chat",_loc35_.Get_SttString());
         }
         else if(_loc2_ == 2)
         {
            $.asTojs("room_data_sys","您已被禁言");
         }
         else if(_loc2_ == 5)
         {
            $.asTojs("room_data_sys","全站禁言");
         }
         else if(_loc2_ == 208)
         {
            $.asTojs("room_data_sys","目标用户未找到");
         }
         else if(_loc2_ == 206)
         {
            $.asTojs("room_data_per","平民5及以下等级用户禁止私聊，赶紧升级吧~");
         }
      }
      
      private function newServerChatContent(param1:String) : void
      {
         var _loc7_:String = null;
         var _loc8_:Boolean = false;
         var _loc9_:Number = NaN;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("uid");
         var _loc4_:String = _loc2_.GetItem("txt");
         var _loc5_:int = _loc2_.GetItemAsInt("col");
         var _loc6_:String = _loc2_.GetItem("nn");
         if(this.myblacklist.indexOf(_loc3_.toString()) == -1)
         {
            _loc7_ = Util.facereplace(_loc4_);
            if(_loc7_ != "")
            {
               _loc8_ = _loc3_ == this.my_uid?true:false;
               if(_loc8_)
               {
                  _loc9_ = new Date().time;
                  _loc10_ = _loc9_ - this.sendTime;
                  if(_loc10_ >= 1000)
                  {
                     _loc11_ = this.sendTime / 1000;
                     UserBehaviorLog.getInstance().sendChatLog(UserBehaviorLog.POINT_ID_CHAT_DELAY,_loc11_,{
                        "id":this.barrage_Conn.ip + ":" + this.barrage_Conn.port,
                        "lag":_loc10_
                     });
                  }
               }
               if(_loc5_ == 0)
               {
                  CommentTime.instance.start(new SingleCommentData(_loc7_,Util.getColor(_loc5_),GlobalData.textSizeValue,getTimer(),_loc8_,GlobalData.danmuModel));
               }
               else
               {
                  ColorComentManager.instance.addColorData({
                     "type":_loc5_,
                     "sender":_loc6_,
                     "content":_loc7_
                  });
               }
            }
         }
         $.asTojs("room_data_chat2",param1);
      }
      
      private function newChatRes(param1:String) : void
      {
         var _loc5_:int = 0;
         var _loc6_:String = null;
         var _loc7_:int = 0;
         var _loc8_:String = null;
         var _loc9_:String = null;
         var _loc10_:Boolean = false;
         var _loc11_:Number = NaN;
         var _loc12_:int = 0;
         var _loc13_:int = 0;
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("len");
         var _loc4_:int = _loc2_.GetItemAsInt("res");
         GlobalData.chatMaxChars = _loc3_;
         $.asTojs("room_data_chat2",param1);
         if(_loc4_ == 356 || _loc4_ == 288)
         {
            _loc5_ = _loc2_.GetItemAsInt("uid");
            _loc6_ = _loc2_.GetItem("txt");
            _loc7_ = _loc2_.GetItemAsInt("col");
            _loc8_ = _loc2_.GetItem("nn");
            if(this.myblacklist.indexOf(_loc5_.toString()) == -1)
            {
               _loc9_ = Util.facereplace(_loc6_);
               if(_loc9_ != "")
               {
                  _loc10_ = _loc5_ == this.my_uid?true:false;
                  if(_loc10_)
                  {
                     _loc11_ = new Date().time;
                     _loc12_ = _loc11_ - this.sendTime;
                     if(_loc12_ >= 1000)
                     {
                        _loc13_ = this.sendTime / 1000;
                        UserBehaviorLog.getInstance().sendChatLog(UserBehaviorLog.POINT_ID_CHAT_DELAY,_loc13_,{
                           "id":this.barrage_Conn.ip + ":" + this.barrage_Conn.port,
                           "lag":_loc12_
                        });
                     }
                  }
                  if(_loc7_ == 0)
                  {
                     CommentTime.instance.start(new SingleCommentData(_loc9_,Util.getColor(_loc7_),GlobalData.textSizeValue,getTimer(),_loc10_,GlobalData.danmuModel));
                  }
                  else
                  {
                     ColorComentManager.instance.addColorData({
                        "type":_loc7_,
                        "sender":_loc8_,
                        "content":_loc9_
                     });
                  }
               }
            }
         }
      }
      
      private function ServerKeepLive(param1:Decode) : void
      {
         var _loc2_:int = param1.GetItemAsInt("tick");
         var _loc3_:int = param1.GetItemAsInt("usernum");
         var _loc4_:Encode = new Encode();
         _loc4_.AddItem("type","keeplive");
         _loc4_.AddItem_int("tick",_loc2_);
         var _loc5_:String = _loc4_.Get_SttString();
         this.keep_online = this.keep_online + this.per_keep_live;
         this.user_count = param1.GetItemAsInt("uc");
         Param.currentNum = this.user_count;
         $.asTojs("room_data_userc",this.user_count);
         if(Param.isYinghun)
         {
            EventCenter.dispatch("TitleBarDataEvent",{"uc":this.user_count});
         }
      }
      
      private function ServerSetAdmin(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("rescode");
         var _loc4_:int = _loc2_.GetItemAsInt("userid");
         var _loc5_:int = _loc2_.GetItemAsInt("opuid");
         var _loc6_:int = _loc2_.GetItemAsInt("group");
         var _loc7_:String = _loc2_.GetItem("adnick");
         var _loc8_:Encode = new Encode();
         _loc8_.AddItem_int("rescode",_loc3_);
         if(_loc3_ == 0)
         {
            _loc8_.AddItem_int("userid",_loc4_);
            _loc8_.AddItem_int("group",_loc6_);
            _loc8_.AddItem_int("opuid",_loc5_);
            _loc8_.AddItem("adnick",_loc7_);
         }
         var _loc9_:String = _loc8_.Get_SttString();
         $.jscall("console.log","setadm： [%s]",param1);
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_setadm",_loc9_);
         }
         else
         {
            $.asTojs("room_data_setadm",param1);
         }
      }
      
      private function ServerBlackUser(param1:Decode) : void
      {
         var _loc8_:* = null;
         var _loc9_:* = null;
         var _loc10_:Encode = null;
         var _loc11_:String = null;
         var _loc2_:int = param1.GetItemAsInt("rescode");
         var _loc3_:int = param1.GetItemAsInt("userid");
         var _loc4_:int = param1.GetItemAsInt("blacktype");
         var _loc5_:int = param1.GetItemAsInt("limittime");
         var _loc6_:String = param1.GetItem("dnick");
         var _loc7_:String = param1.GetItem("snick");
         if(_loc2_ == 0)
         {
            if(_loc4_ == 1)
            {
               _loc9_ = _loc6_ + "被管理员" + _loc7_ + "封锁IP";
               _loc8_ = "您已被管理员" + _loc7_ + "封锁IP,封锁时间:" + _loc5_ + "秒";
            }
            else if(_loc4_ == 2 || _loc4_ == 4)
            {
               if(_loc5_ != 0)
               {
                  _loc9_ = _loc6_ + "被管理员" + _loc7_ + "禁言";
                  _loc8_ = "您已被管理员" + _loc7_ + "禁言,禁言时间:" + _loc5_ + "秒";
               }
               else
               {
                  _loc9_ = _loc6_ + "被管理员解除禁言";
                  _loc8_ = "您已被管理员解禁";
               }
            }
            else if(_loc4_ == 3)
            {
               _loc9_ = _loc6_ + "被管理员" + _loc7_ + "T出房间";
               _loc8_ = "您已被管理员" + _loc7_ + "封锁帐号,封锁时间:" + _loc5_ + "秒";
            }
            if(this.my_uid == _loc3_)
            {
               $.jscall("console.log","forbidTip:",_loc8_);
               $.asTojs("room_data_per",_loc8_);
               if(_loc4_ == 1 && _loc4_ == 3)
               {
                  this.clean_conn_timer();
               }
            }
            $.asTojs("room_data_sys",_loc9_);
         }
         else
         {
            _loc10_ = new Encode();
            _loc10_.AddItem_int("rescode",_loc2_);
            _loc11_ = _loc10_.Get_SttString();
            $.asTojs("room_data_admfail",_loc11_);
         }
      }
      
      private function ServerRoomRefresh(param1:Decode) : void
      {
         this.serialnum = param1.GetItemAsInt("serialnum");
         this.user_count = param1.GetItemAsInt("c");
         Param.currentNum = this.user_count;
         $.asTojs("room_data_userc",this.user_count);
      }
      
      private function ServerError(param1:Decode) : void
      {
         var randTime:int = 0;
         var _strdecode:Decode = param1;
         this.clean_conn_timer();
         var code:int = _strdecode.GetItemAsInt("code");
         code = code % 10000;
         var _strencode:Encode = new Encode();
         _strencode.AddItem("type","error");
         _strencode.AddItem_int("code",code);
         var server_error_str:String = _strencode.Get_SttString();
         $.jscall("console.log","server_error [%s]",server_error_str);
         if(code == 205)
         {
            $.asTojs("room_data_sererr",server_error_str);
            EventCenter.dispatch("login",{"code":1});
         }
         if(code == 52)
         {
            if(Param.IS_HOSTLIVE == 1 || Param.usergroupid == "5")
            {
               $.jscall("console.log","ServerShowStatus0 =" + 1);
               $.asTojs("room_data_sererr",this.endError);
               this.dispatcher.dispatchEvent(new Event("ServerShowStatus"));
            }
            else
            {
               this.endError = server_error_str;
               clearTimeout(this.endTimeIndex0);
               randTime = int(Math.random() * 30);
               $.jscall("console.log","ServerShowStatus0 =" + randTime);
               this.endTimeIndex0 = setTimeout(function():void
               {
                  $.asTojs("room_data_sererr",endError);
                  dispatcher.dispatchEvent(new Event("ServerShowStatus"));
               },randTime * 1000);
            }
         }
         $.asTojs("room_data_flaerr",code);
         $.jscall("console.log","flash error : ");
      }
      
      private function ServerRepeaterlist(param1:Decode) : void
      {
         var _loc4_:Decode = null;
         var _loc5_:int = 0;
         var _loc6_:String = null;
         var _loc7_:Decode = null;
         var _loc2_:int = param1.GetItemAsInt("rid");
         var _loc3_:String = param1.GetItem("list");
         if(_loc3_ != "")
         {
            _loc4_ = new Decode();
            _loc4_.Parse(_loc3_);
            _loc5_ = 0;
            while(_loc5_ < _loc4_.count)
            {
               _loc6_ = _loc4_.GetItemByIndex(_loc5_);
               _loc7_ = new Decode();
               _loc7_.Parse(_loc6_);
               this.serverArray[_loc5_] = new Array();
               this.serverArray[_loc5_]["nr"] = _loc7_.GetItemAsInt("nr");
               this.serverArray[_loc5_]["ip"] = _loc7_.GetItem("ip");
               this.serverArray[_loc5_]["port"] = _loc7_.GetItemAsInt("port");
               _loc5_++;
            }
            if(this.barrage_Conn != null)
            {
               this.barrage_Conn.UserLogout();
               this.barrage_Conn.dispatcher.removeEventListener("ServerShowStatus",this.__ShowStatus);
               this.barrage_Conn.clean_conn_timer();
               this.barrage_Conn = null;
            }
            this.barrage_Conn = new cc.dy.model.net.ClientBarrage(this._conn);
            this.barrage_Conn.dispatcher.addEventListener("ServerShowStatus",this.__ShowStatus);
            this.barrage_Conn.my_uid = this.my_uid;
            this.barrage_Conn.my_username = this.my_username;
            this.barrage_Conn.my_nickname = this.my_nickname;
            this.barrage_Conn.roomId = this.roomId;
            this.barrage_Conn.serverArray = this.serverArray;
            this.barrage_Conn.OnChatMsg = this.ServerChatContent;
            this.barrage_Conn.newOnChatMsg = this.newServerChatContent;
            this.barrage_Conn.ConnectNewServer();
         }
      }
      
      private function ServerSetGroup(param1:Decode) : void
      {
         var _loc2_:int = param1.GetItemAsInt("gid");
         this.barrage_Conn.my_gid = _loc2_;
         this.barrage_Conn.UserJoinGroup();
      }
      
      private function ServerJoinGroup(param1:Decode) : void
      {
      }
      
      private function systemBroadcast(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("t");
         var _loc4_:int = _loc2_.GetItemAsInt("bt");
         var _loc5_:int = _loc2_.GetItemAsInt("vt");
         var _loc6_:String = _loc2_.GetItem("sn");
         var _loc7_:String = _loc2_.GetItem("c");
         var _loc8_:String = _loc2_.GetItem("url");
         var _loc9_:Encode = new Encode();
         _loc9_.AddItem_int("bt",_loc4_);
         _loc9_.AddItem_int("vt",_loc5_);
         _loc9_.AddItem("sn",_loc6_);
         _loc9_.AddItem("c",_loc7_);
         _loc9_.AddItem("url",_loc8_);
         $.jscall("console.log","sysbroad:",_loc9_.Get_SttString());
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_brocast",_loc9_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_brocast",param1);
         }
      }
      
      private function fishPresent(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("r");
         var _loc4_:int = _loc2_.GetItemAsInt("mg");
         var _loc5_:int = _loc2_.GetItemAsInt("ms");
         var _loc6_:int = _loc2_.GetItemAsInt("gb");
         var _loc7_:int = _loc2_.GetItemAsInt("sb");
         var _loc8_:int = _loc2_.GetItemAsInt("hc");
         var _loc9_:String = _loc2_.GetItem("sui");
         var _loc10_:Number = _loc2_.GetItemAsNumber("src_strength");
         var _loc11_:Number = _loc2_.GetItemAsNumber("dst_weight");
         var _loc12_:Decode = new Decode();
         _loc12_.Parse(_loc9_);
         var _loc13_:String = _loc12_.GetItem("nick");
         var _loc14_:Encode = new Encode();
         _loc14_.AddItem_int("r",_loc3_);
         _loc14_.AddItem_int("mg",_loc4_);
         _loc14_.AddItem_int("ms",_loc5_);
         _loc14_.AddItem_int("gb",_loc6_);
         _loc14_.AddItem_int("sb",_loc7_);
         _loc14_.AddItem("sui",_loc9_);
         _loc14_.AddItem_int("src_strength",_loc10_);
         _loc14_.AddItem_int("dst_weight",_loc11_);
         _loc14_.AddItem_int("hc",_loc8_);
         _loc14_.AddItem("type","donateres");
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_gift",_loc14_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_gift",param1);
         }
         if(Param.isYinghun)
         {
            EventCenter.dispatch("TitleBarDataEvent",{"weight":_loc11_});
         }
      }
      
      private function taskList(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:String = _loc2_.GetItem("list");
         var _loc4_:Encode = new Encode();
         _loc4_.AddItem("list",_loc3_);
         $.jscall("console.log","tkss:",_loc4_.Get_SttString());
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_tasklis",_loc4_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_tasklis",param1);
         }
      }
      
      private function taskNum(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("ps");
         var _loc4_:Encode = new Encode();
         _loc4_.AddItem_int("ps",_loc3_);
         $.jscall("console.log","tkn:",_loc4_.Get_SttString());
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_taskcou",_loc4_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_taskcou",param1);
         }
      }
      
      private function obtainTaskRes(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("r");
         var _loc4_:int = _loc2_.GetItemAsInt("tid");
         var _loc5_:int = _loc2_.GetItemAsInt("mg");
         var _loc6_:int = _loc2_.GetItemAsInt("ms");
         var _loc7_:Number = _loc2_.GetItemAsNumber("gb");
         var _loc8_:Number = _loc2_.GetItemAsNumber("sb");
         var _loc9_:Encode = new Encode();
         _loc9_.AddItem_int("r",_loc3_);
         _loc9_.AddItem_int("tid",_loc4_);
         _loc9_.AddItem_int("mg",_loc5_);
         _loc9_.AddItem_int("ms",_loc6_);
         _loc9_.AddItem_int("gb",_loc7_);
         _loc9_.AddItem_int("sb",_loc8_);
         $.jscall("console.log","rtkr:",_loc9_.Get_SttString());
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_taskrec",_loc9_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_taskrec",param1);
         }
      }
      
      private function roomSignUpRes(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("r");
         var _loc4_:int = _loc2_.GetItemAsInt("sc");
         var _loc5_:Encode = new Encode();
         _loc5_.AddItem_int("r",_loc3_);
         _loc5_.AddItem_int("sc",_loc4_);
         $.jscall("console.log","rsignr:",_loc5_.Get_SttString());
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_tasksign",_loc5_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_tasksign",param1);
         }
      }
      
      private function onlineGiftRes(param1:Decode) : void
      {
         var _loc2_:int = param1.GetItemAsInt("lv");
         var _loc3_:int = param1.GetItemAsInt("t");
         var _loc4_:int = param1.GetItemAsInt("dl");
         var _loc5_:Encode = new Encode();
         _loc5_.AddItem_int("lev",_loc2_);
         _loc5_.AddItem_int("lack_time",_loc3_);
         _loc5_.AddItem_int("dl",_loc4_);
         $.jscall("console.log","onlineTreasurer:",_loc5_.Get_SttString());
         $.asTojs("room_data_chest",_loc5_.Get_SttString());
      }
      
      private function keyTitlesRes(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("uid");
         var _loc4_:String = _loc2_.GetItem("uname");
         var _loc5_:int = _loc2_.GetItemAsInt("ret");
         var _loc6_:Encode = new Encode();
         _loc6_.AddItem("uname",_loc4_);
         _loc6_.AddItem_int("ret",_loc5_);
         _loc6_.AddItem_int("uid",_loc3_);
         $.jscall("console.log","keytitler:",_loc6_.Get_SttString());
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_onekeyacc",_loc6_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_onekeyacc",param1);
         }
      }
      
      private function giveFishBall(param1:String) : void
      {
         var _strdecode:Decode = null;
         var r:int = 0;
         var ms:int = 0;
         var sb:Number = NaN;
         var strength:Number = NaN;
         var _strencode:Encode = null;
         var str:String = param1;
         _strdecode = new Decode();
         _strdecode.Parse(str);
         r = _strdecode.("r");
         ms = _strdecode.GetItemAsInt("ms");
         sb = _strdecode.GetItemAsNumber("sb");
         strength = _strdecode.GetItemAsNumber("strength");
         _strencode = new Encode();
         _strencode.AddItem_int("r",r);
         _strencode.AddItem_int("ms",ms);
         _strencode.AddItem_int("sb",sb);
         _strencode.AddItem_int("strength",strength);
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_balance",_strencode.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_balance",str);
         }
      }
      
      private function talkRestriction(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("cd");
         var _loc4_:int = _loc2_.GetItemAsInt("maxl");
         var _loc5_:Encode = new Encode();
         _loc5_.AddItem_int("cd",_loc3_);
         _loc5_.AddItem_int("maxl",_loc4_);
         $.jscall("console.log","limitchatr:",_loc5_.Get_SttString());
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_chatcd",_loc5_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_chatcd",param1);
         }
      }
      
      private function baoXuetime(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:String = _loc2_.GetItem("func");
         var _loc4_:String = _loc2_.GetItem("param");
         var _loc5_:Encode = new Encode();
         _loc5_.AddItem("func",_loc3_);
         _loc5_.AddItem("param",_loc4_);
         if(GlobalData.OldModel)
         {
            $.asTojs("room_bus_comcall",_loc5_.Get_SttString());
         }
         else
         {
            $.asTojs("room_bus_comcall",param1);
         }
         $.jscall("console.log","common_call1：",_loc5_.Get_SttString());
      }
      
      private function reportBarrage(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("state");
         var _loc4_:Encode = new Encode();
         _loc4_.AddItem_int("state",_loc3_);
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_chatrep",_loc4_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_chatrep",param1);
         }
         $.jscall("console.log","return_chatreport：",_loc4_.Get_SttString());
      }
      
      private function identityChange(param1:Decode) : void
      {
         var _loc2_:int = param1.GetItemAsInt("opuid");
         var _loc3_:int = param1.GetItemAsInt("rg");
         var _loc4_:int = param1.GetItemAsInt("rid");
         GlobalData.rg = _loc3_;
         EventCenter.dispatch("userRGEvent",null);
         $.jscall("console.log","identityChange");
      }
      
      private function rewardListResponse(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("rid");
         var _loc4_:String = _loc2_.GetItem("list");
         var _loc5_:String = _loc2_.GetItem("list_all");
         var _loc6_:Encode = new Encode();
         _loc6_.AddItem_int("rid",_loc3_);
         _loc6_.AddItem("list",_loc4_);
         _loc6_.AddItem("list_all",_loc5_);
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_cqrank",_loc6_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_cqrank",param1);
         }
         $.jscall("console.log","return_rewardList：",_loc6_.Get_SttString());
      }
      
      private function emailNotify(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:String = _loc2_.GetItem("mid");
         var _loc4_:String = _loc2_.GetItem("sender");
         var _loc5_:String = _loc2_.GetItem("sub");
         var _loc6_:int = _loc2_.GetItemAsInt("unread");
         var _loc7_:Encode = new Encode();
         _loc7_.AddItem("mid",_loc3_);
         _loc7_.AddItem("sender",_loc4_);
         _loc7_.AddItem("sub",_loc5_);
         _loc7_.AddItem_int("unread",_loc6_);
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_letter",_loc7_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_letter",param1);
         }
         $.jscall("console.log","return_emailNotify：",_loc7_.Get_SttString());
      }
      
      private function updateYC(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("b");
         var _loc4_:Encode = new Encode();
         _loc4_.AddItem_int("b",_loc3_);
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_ycchange",_loc4_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_ycchange",param1);
         }
         $.jscall("console.log","updateyc：",_loc4_.Get_SttString());
      }
      
      private function roomInfoRes(param1:String) : void
      {
         var _loc4_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc6_:int = 0;
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         if(Param.isYinghun)
         {
            _loc4_ = _loc2_.GetItemAsNumber("weight");
            _loc5_ = _loc2_.GetItemAsNumber("fans_count");
            _loc6_ = _loc2_.GetItemAsInt("fl");
            EventCenter.dispatch("TitleBarDataEvent",{
               "weight":_loc4_,
               "fans_count":_loc5_,
               "fl":_loc6_
            });
         }
         $.asTojs("room_data_info",param1);
         $.jscall("console.log","show_obj.info_showr：",param1);
         var _loc3_:String = _loc2_.GetItem("tvt");
         if(_loc3_ != "")
         {
            EventCenter.dispatch("VotesChanged",{"tvt":_loc3_});
         }
      }
      
      private function giftPkgRes(param1:String) : void
      {
         $.asTojs("room_data_chestquery",param1);
         $.jscall("console.log","query_gift_pkg_info：",param1);
      }
      
      private function giveFishBallres(param1:String) : void
      {
         $.asTojs("room_data_giftbat1",param1);
         $.jscall("console.log","live_gift_batter1：",param1);
      }
      
      private function reloadStreamNotify() : void
      {
         clearTimeout(this.reloadTimeIndex);
         var _loc1_:int = int(Math.random() * 30);
         this.reloadTimeIndex = setTimeout(this.reloadStream,_loc1_ * 1000 + 60000);
      }
      
      private function verResponse(param1:Decode) : void
      {
         var _loc2_:int = param1.GetItemAsInt("v");
         $.asTojs("room_bus_login2",0);
      }
      
      private function randomStrResponse(param1:Decode) : void
      {
         this.randomValue = param1.GetItemAsInt("r");
         this.salt = param1.GetItem("s");
         $.asTojs("loginBranch",1);
      }
      
      private function expUpdate(param1:String) : void
      {
         $.asTojs("room_data_expchange",param1);
         $.jscall("console.log","exprienceupdate:",param1);
      }
      
      private function gapNotify(param1:String) : void
      {
         $.asTojs("room_data_rankgap",param1);
         $.jscall("console.log","rankgapnotify：",param1);
      }
      
      private function initChatLimit(param1:String) : void
      {
         $.asTojs("room_data_chatinit",param1);
         $.jscall("console.log","newuserchatlimit：",param1);
      }
      
      private function hbGetResponse(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("rpt");
         switch(_loc3_)
         {
            case 0:
               $.asTojs("room_data_giftbat1",param1);
               $.jscall("console.log","live_gift_batter4：",param1);
               break;
            case 1:
               $.jscall("treeReply",param1);
               $.jscall("console.log","treeReply gateway: ",param1);
               break;
            case 2:
               $.asTojs("room_data_beastrep",param1);
               $.jscall("console.log","beastReply gateway : ",param1);
               break;
            case 3:
               $.asTojs("room_data_sabonusget",param1);
               $.jscall("console.log","beastReply gateway : ",param1);
               break;
            default:
               $.jscall("console.log","unknown rpt type : ",_loc3_);
         }
      }
      
      private function reloadStream() : void
      {
         EventCenter.dispatch("ReloadStreamEvent",null);
      }
      
      private function ServerShowStatus(param1:Decode) : void
      {
         var randTime:int = 0;
         var _strdecode:Decode = param1;
         var rid:int = _strdecode.GetItemAsInt("rid");
         var ss:int = _strdecode.GetItemAsInt("ss");
         var code:int = _strdecode.GetItemAsInt("code");
         var notify:int = _strdecode.GetItemAsInt("notify");
         var endtime:int = _strdecode.GetItemAsInt("endtime");
         var rt:int = _strdecode.GetItemAsInt("rt");
         var rtv:int = _strdecode.GetItemAsInt("rtv");
         var _strencode:Encode = new Encode();
         _strencode.AddItem_int("rid",rid);
         _strencode.AddItem_int("ss",ss);
         _strencode.AddItem_int("code",code);
         _strencode.AddItem_int("notify",notify);
         _strencode.AddItem_int("endtime",endtime);
         _strencode.AddItem_int("rt",rt);
         _strencode.AddItem_int("rtv",rtv);
         this.endStr = _strencode.Get_SttString();
         if(rt == 1)
         {
            Param.isTicketNeed = true;
            setTimeout(function():void
            {
               var _loc1_:PlayMediator = MainCoreFacade.getInstance().retrieveMediator("PlayMediator") as PlayMediator;
               if(!_loc1_.playView.isPause)
               {
                  EventCenter.dispatch("TicketStreamNotify");
               }
               EventCenter.dispatch("ChangeRateNotifyEvent",{"type":0});
               $.jscall("console.log","gw ticket notify!");
            },int(Math.random() * 5000));
         }
         else if(rt == 2)
         {
            EventCenter.dispatch("PwdNotifyEvent",{"type":rtv});
         }
         else if(Param.IS_HOSTLIVE == 1 || Param.usergroupid == "5")
         {
            $.jscall("console.log","ServerShowStatus1 =" + 2);
            $.jscall("console.log","nsStatechange:",this.endStr);
            $.asTojs("room_data_state",this.endStr);
            this.dispatcher.dispatchEvent(new Event("ServerShowStatus"));
            EventCenter.dispatch("hostGoBack");
         }
         else
         {
            clearTimeout(this.endTimeIndex);
            randTime = int(Math.random() * 30);
            $.jscall("console.log","ServerShowStatus1 =" + randTime);
            this.endTimeIndex = setTimeout(function():void
            {
               $.jscall("console.log","nsStatechange:",endStr);
               $.asTojs("room_data_state",endStr);
               dispatcher.dispatchEvent(new Event("ServerShowStatus"));
               EventCenter.dispatch("hostGoBack");
            },randTime * 1000);
         }
      }
      
      private function __ShowStatus(param1:Event) : void
      {
         this.dispatcher.dispatchEvent(new Event("ServerShowStatus"));
      }
      
      private function findUserByUID(param1:int) : RoomUser
      {
         var _loc2_:int = 0;
         _loc2_ = 0;
         while(_loc2_ < this.users.length)
         {
            if(this.users[_loc2_].uid == param1)
            {
               return this.users[_loc2_];
            }
            _loc2_++;
         }
         return null;
      }
      
      private function findUserByUsername(param1:String) : RoomUser
      {
         var _loc2_:int = 0;
         _loc2_ = 0;
         while(_loc2_ < this.users.length)
         {
            if(this.users[_loc2_].username == param1)
            {
               return this.users[_loc2_];
            }
            _loc2_++;
         }
         return null;
      }
      
      private function findUserByNickname(param1:String) : RoomUser
      {
         var _loc2_:int = 0;
         _loc2_ = 0;
         while(_loc2_ < this.users.length)
         {
            if(this.users[_loc2_].nickname == param1)
            {
               return this.users[_loc2_];
            }
            _loc2_++;
         }
         return null;
      }
      
      private function removeUserByUID(param1:int) : void
      {
         var _loc2_:int = 0;
         _loc2_ = 0;
         while(_loc2_ < this.users.length)
         {
            if(this.users[_loc2_].uid == param1)
            {
               this.users.splice(_loc2_,1);
               return;
            }
            _loc2_++;
         }
      }
      
      private function sortUsers(param1:RoomUser, param2:RoomUser) : int
      {
         var _loc3_:int = this.sortAtt(param1.roomgroup,param2.roomgroup);
         if(_loc3_ != 0)
         {
            return _loc3_;
         }
         return this.sortAtt(param1.score,param2.score);
      }
      
      private function sortAtt(param1:int, param2:int) : int
      {
         if(param1 > param2)
         {
            return -1;
         }
         if(param1 < param2)
         {
            return 1;
         }
         return 0;
      }
      
      public function black_word(param1:String) : Boolean
      {
         var _loc3_:String = null;
         var _loc2_:Array = new Array("风云直播","YY直播");
         for each(_loc3_ in _loc2_)
         {
            if(param1.indexOf(_loc3_) >= 0)
            {
               return true;
            }
         }
         return false;
      }
      
      public function clean_conn_timer() : void
      {
         if(this.myTimer != null)
         {
            this.myTimer.stop();
            this.myTimer.removeEventListener(TimerEvent.TIMER,this.KeepLive);
            this.myTimer = null;
         }
         if(this.cacheTimer != null)
         {
            this.cacheTimer.stop();
            this.cacheTimer.removeEventListener(TimerEvent.TIMER,this.RoomRefresh);
            this.cacheTimer = null;
         }
         if(this._conn != null)
         {
            this._conn.close();
            this._conn.removeEventListener(TcpEvent.Conneted,this._OnConn);
            this._conn.removeEventListener(TcpEvent.RecvMsg,this.ParseMsg);
            this._conn.removeEventListener(TcpEvent.SecurityError,this._OnConn);
            this._conn.removeEventListener(TcpEvent.Error,this._OnConn);
            this._conn.removeEventListener(TcpEvent.Closed,this._OnConn);
            this._conn = null;
         }
         if(this.barrage_Conn != null)
         {
            this.barrage_Conn.UserLogout();
            this.barrage_Conn = null;
         }
      }
      
      private function christmasTree(param1:String) : void
      {
         $.jscall("treeReceived",param1);
      }
      
      private function beastReceived(param1:String) : void
      {
         $.asTojs("room_data_beastrec",param1);
      }
      
      private function petInfo(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("pt");
         switch(_loc3_)
         {
            case 1:
               this.christmasTree(param1);
               break;
            case 2:
               this.beastReceived(param1);
               break;
            default:
               $.jscall("console.log","unknown pt type: ",_loc3_);
         }
      }
      
      private function petReceived(param1:String) : void
      {
         $.asTojs("room_data_petrec",param1);
      }
      
      private function alipayblackres(param1:Decode) : void
      {
         var _loc4_:String = null;
         var _loc2_:int = param1.GetItemAsInt("rescode");
         var _loc3_:int = param1.GetItemAsInt("userid");
         if(_loc2_ == 0)
         {
            _loc4_ = "禁言支付宝用户成功";
         }
         else
         {
            _loc4_ = "禁言支付宝用户失败";
         }
         $.jscall("console.log","alipayblackres:",_loc4_);
      }
      
      private function room_data_sys(param1:String) : void
      {
         $.asTojs("room_data_sys",param1);
         $.jscall("console.log","gw room_data_sys:",param1);
      }
      
      private function room_data_giftbat1(param1:String) : void
      {
         $.asTojs("room_data_giftbat1",param1);
         $.jscall("console.log","gw room_data_giftbat1:",param1);
      }
   }
}
