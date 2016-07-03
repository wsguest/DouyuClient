package cc.dy.model.net
{
   import flash.events.EventDispatcher;
   import flash.utils.Timer;
   import flash.utils.setTimeout;
   import util.$;
   import util.UserBehaviorLog;
   import flash.utils.clearInterval;
   import flash.utils.setInterval;
   import flash.utils.getTimer;
   import sample.loaderDanmu.CModule;
   import flash.events.TimerEvent;
   import common.event.EventCenter;
   import cc.dy.view.play.PlayMediator;
   import flash.utils.clearTimeout;
   import flash.events.Event;
   import util.Util;
   import util.CommonUtils;
   
   public class ClientBarrage
   {
       
      public var _conn2:cc.dy.model.net.TcpClient;
      
      public var dispatcher:EventDispatcher;
      
      public var login_status:Boolean = false;
      
      public var my_uid:int;
      
      public var my_username:String;
      
      public var my_nickname:String;
      
      public var my_gid:int = -1;
      
      public var roomId:int;
      
      public var keep_online:int = 0;
      
      private var myTimer:Timer;
      
      private var joinGroupTimer:Timer;
      
      private var per_keep_live:int = 45;
      
      private var per_cachedata:int = 60;
      
      private var serialnum:int = 0;
      
      private var user_count:int = 0;
      
      public var serverArray:Array;
      
      public var OnChatMsg:Function;
      
      public var newOnChatMsg:Function;
      
      private var firstConn:cc.dy.model.net.TcpClient;
      
      private var flashProt:int = 0;
      
      private var protArr:Array;
      
      private var firstRepeatConnect:Boolean = true;
      
      private var _ip:String;
      
      private var _port:int;
      
      private var firstTime:Number;
      
      private var secondTime:Number;
      
      private var fristConnect:Boolean = true;
      
      private var firstTimeOut:Boolean = true;
      
      private var _checkOnlineSeed:uint;
      
      private var breakLine:uint;
      
      private var countNet:int = 0;
      
      private var serverId:int;
      
      private var endTimeIndex:uint;
      
      private var endStr:String;
      
      private var illCloseIndex:uint;
      
      public function ClientBarrage(param1:cc.dy.model.net.TcpClient)
      {
         this.dispatcher = new EventDispatcher();
         this.serverArray = new Array();
         this.protArr = [843,844];
         super();
         this.firstConn = param1;
         this.flashProt = this.protArr[int(this.protArr.length * Math.random())];
      }
      
      public function get ip() : String
      {
         return this._ip;
      }
      
      public function get port() : int
      {
         return this._port;
      }
      
      public function ConnectNewServer() : void
      {
         var _loc1_:int = 0;
         this.clean_conn_timer();
         this._conn2 = new cc.dy.model.net.TcpClient(GlobalData.isSecurError2);
         if(this.serverArray.length > 0)
         {
            if(this.fristConnect)
            {
               setTimeout(this.__recodeFirst,2000);
            }
            this.fristConnect = false;
            _loc1_ = int(Math.random() * 10000) % this.serverArray.length;
            this._ip = this.serverArray[_loc1_]["ip"];
            this._port = this.serverArray[_loc1_]["port"];
            this._conn2.connect(this._ip,this._port,this.flashProt);
            this._conn2.addEventListener(TcpEvent.Conneted,this.onConn);
            this._conn2.addEventListener(TcpEvent.RecvMsg,this.ParseMsg);
            this._conn2.addEventListener(TcpEvent.SecurityError,this.onConn);
            this._conn2.addEventListener(TcpEvent.Error,this.onConn);
            this._conn2.addEventListener(TcpEvent.Closed,this.onConn);
            $.jscall("console.log","dmnc");
         }
      }
      
      private function __recodeFirst() : void
      {
         var _loc1_:int = 0;
         if(this.firstTimeOut)
         {
            _loc1_ = new Date().time / 1000;
            UserBehaviorLog.getInstance().sendChatLog(UserBehaviorLog.POINT_ID_FIRST_LOGIN_DANMU,_loc1_,{"id":this._ip + ":" + this._port});
         }
      }
      
      public function onConn(param1:TcpEvent) : void
      {
         var _loc2_:int = 0;
         this.firstTimeOut = false;
         $.jscall("console.log","dmncr");
         if(param1._param.type == 1)
         {
            GlobalData.isSecurError2 = false;
            this.UserLogin();
         }
         else if(param1._param.type == 3)
         {
            GlobalData.isSecurError2 = true;
            _loc2_ = param1._param.port;
            this.flashProt = _loc2_ == 843?844:843;
            if(this.firstRepeatConnect)
            {
               this.firstRepeatConnect = false;
               this.ConnectNewServer();
            }
         }
         if(this._checkOnlineSeed)
         {
            clearInterval(this._checkOnlineSeed);
         }
         this._checkOnlineSeed = setInterval(this.CheckOnline,120000);
      }
      
      private function breakOnline() : void
      {
         if(Boolean(this._conn2) && Boolean(this._conn2.is_connected))
         {
            this._conn2.close();
            $.jscall("console.log","cutdmcn");
         }
      }
      
      private function CheckOnline() : void
      {
         var _loc1_:int = 0;
         if(Boolean(this.firstConn) && Boolean(this.firstConn.is_connected))
         {
            if(!this._conn2 || !this._conn2.is_connected)
            {
               $.jscall("console.log","cnc");
               this.ConnectNewServer();
               this.countNet++;
               _loc1_ = new Date().time / 1000;
               UserBehaviorLog.getInstance().sendChatLog(UserBehaviorLog.POINT_ID_LOGIN_DANMU_FAIL,_loc1_,{
                  "id":this.ip + ":" + this.port,
                  "lag":this.countNet
               });
            }
         }
      }
      
      public function UserLogin() : void
      {
         if(this._conn2 == null)
         {
            return;
         }
         this.firstTime = getTimer();
         var _loc1_:String = this.my_username;
         var _loc2_:String = "1234567890123456";
         this.roomId = this.roomId;
         this._conn2.addEventListener(TcpEvent.RecvMsg,this.ParseMsg);
         var _loc3_:Encode = new Encode();
         _loc3_.AddItem("type","loginreq");
         _loc3_.AddItem("username",_loc1_);
         _loc3_.AddItem("password",_loc2_);
         _loc3_.AddItem_int("roomid",this.roomId);
         var _loc4_:String = _loc3_.Get_SttString();
         var _loc5_:int = CModule.malloc(4);
         var _loc6_:int = loaderDanmu.danmakuGetLoginMsgRepeaterData(_loc1_,_loc5_);
         var _loc7_:int = CModule.read32(_loc5_);
         var _loc8_:String = CModule.readString(_loc7_,_loc6_);
         $.jscall("console.log","UserLogin [%s]",_loc8_);
         this._conn2.sendmsg(_loc8_);
         loaderDanmu.danmakuFreeData(_loc5_);
         CModule.free(_loc5_);
      }
      
      public function UserJoinGroup() : void
      {
         if(this.login_status == false)
         {
            return;
         }
         var _loc1_:Encode = new Encode();
         _loc1_.AddItem("type","joingroup");
         _loc1_.AddItem_int("rid",this.roomId);
         _loc1_.AddItem_int("gid",this.my_gid);
         var _loc2_:String = _loc1_.Get_SttString();
         if(this._conn2 == null)
         {
            return;
         }
         var _loc3_:int = CModule.malloc(4);
         var _loc4_:int = loaderDanmu.danmakuGetJoinGroupData(this.roomId,this.my_gid,_loc3_);
         var _loc5_:int = CModule.read32(_loc3_);
         this._conn2.sendmsg(CModule.readString(_loc5_,_loc4_));
         loaderDanmu.danmakuFreeData(_loc3_);
         CModule.free(_loc3_);
      }
      
      public function UserLogout() : void
      {
         var _loc1_:Encode = null;
         var _loc2_:String = null;
         if(this._conn2 != null)
         {
            $.jscall("console.log","ulo");
            _loc1_ = new Encode();
            _loc1_.AddItem("type","logout");
            _loc2_ = _loc1_.Get_SttString();
            this._conn2.sendmsg(_loc2_);
            if(this._checkOnlineSeed)
            {
               clearInterval(this._checkOnlineSeed);
            }
            this.clean_conn_timer();
         }
      }
      
      public function KeepLive(param1:TimerEvent) : void
      {
         var _loc2_:Encode = null;
         var _loc3_:String = null;
         if(this._conn2 != null)
         {
            _loc2_ = new Encode();
            _loc2_.AddItem("type","mrkl");
            _loc3_ = _loc2_.Get_SttString();
            this._conn2.sendmsg(_loc3_);
            $.jscall("console.log","time1=" + getTimer());
         }
      }
      
      public function CheckJoinGroup(param1:TimerEvent) : void
      {
         if(this._conn2 != null)
         {
            if(this.login_status == true && this.my_gid != -1)
            {
               this.joinGroupTimer.stop();
               this.joinGroupTimer = null;
               this.UserJoinGroup();
            }
         }
      }
      
      private function ParseMsg(param1:TcpEvent) : void
      {
         var _loc2_:String = param1._param as String;
         var _loc3_:Decode = new Decode();
         _loc3_.Parse(_loc2_);
         var _loc4_:String = _loc3_.GetItem("type");
         if(_loc4_ != "keeplive" && _loc4_ != "chatmessage" && _loc4_ != "donateres" && _loc4_ != "dgn" && _loc4_ != "dgb" && _loc4_ != "chatmsg" && _loc4_ != "mrkl")
         {
            $.jscall("console.log","弹幕 网络数据 [%s]",_loc2_);
         }
         if(_loc4_ == "loginres")
         {
            this.ServerLoginInfo(_loc3_);
         }
         else if(_loc4_ == "chatmessage")
         {
            this.ServerChatContent(_loc3_);
         }
         else if(_loc4_ == "chatmsg")
         {
            this.newServerChatContent(_loc2_);
         }
         else if(_loc4_ == "keeplive")
         {
            this.ServerKeepLive(_loc3_);
         }
         else if(_loc4_ == "mrkl")
         {
            this.newServerKeepLive(_loc3_);
         }
         else if(_loc4_ == "error")
         {
            this.ServerError(_loc3_);
         }
         else if(_loc4_ == "donateres")
         {
            this.fishPresent(_loc2_);
         }
         else if(_loc4_ == "setadminres")
         {
            this.ServerSetAdmin(_loc3_);
         }
         else if(_loc4_ == "blackres")
         {
            this.ServerBlackUser(_loc3_);
         }
         else if(_loc4_ == "rss")
         {
            this.ServerShowStatus(_loc3_);
         }
         else if(_loc4_ == "rsm")
         {
            this.systemBroadcast(_loc2_);
         }
         else if(_loc4_ == "userenter")
         {
            this.ServerUserEnter(_loc2_);
         }
         else if(_loc4_ == "uenter")
         {
            this.newServerUserEnter(_loc2_);
         }
         else if(_loc4_ == "bc_buy_deserve")
         {
            this.buyDeserve(_loc2_);
         }
         else if(_loc4_ == "common_call")
         {
            this.baoxueTime(_loc2_);
         }
         else if(_loc4_ == "ranklist")
         {
            this.rewardListResponse(_loc2_);
         }
         else if(_loc4_ == "filterblackad")
         {
            this.maskQrCodeNotify(_loc3_);
         }
         else if(_loc4_ == "hits_effect")
         {
            this.batterFxEffect(_loc2_);
         }
         else if(_loc4_ == "onlinegift")
         {
            this.onGiftNotify(_loc2_);
         }
         else if(_loc4_ == "spbc")
         {
            this.giftBroadcast(_loc2_);
         }
         else if(_loc4_ == "dgn")
         {
            this.currentRoomGiftBroadcast(_loc2_);
         }
         else if(_loc4_ == "dgb")
         {
            this.currentRoomGiftBroadcast(_loc2_);
         }
         else if(_loc4_ == "ssd")
         {
            this.superDanmuBroadcast(_loc2_);
         }
         else if(_loc4_ == "gbbc")
         {
            this.hbNotify(_loc2_);
         }
         else if(_loc4_ == "ggbb")
         {
            this.hbGetNotify(_loc2_);
         }
         else if(_loc4_ == "gbip")
         {
            this.hbForNewuserNotify(_loc2_);
         }
         else if(_loc4_ == "rii")
         {
            this.illegalNotify(_loc2_);
         }
         else if(_loc4_ == "rankup")
         {
            this.rankUpdate(_loc2_);
         }
         else if(_loc4_ == "upgrade")
         {
            this.userUpdate(_loc2_);
         }
         else if(_loc4_ == "gift_title")
         {
            this.levelIconNotify(_loc2_);
         }
         else if(_loc4_ == "pet_info")
         {
            this.christmasTree(_loc2_);
         }
         else if(_loc4_ == "cgn")
         {
            this.christmasGift(_loc2_);
         }
         else if(_loc4_ == "bcrp")
         {
            this.petInfo(_loc2_);
         }
         else if(_loc4_ == "acc")
         {
            this.deductionPoints(_loc2_);
         }
         else if(_loc4_ == "bcar")
         {
            this.nianNotify(_loc3_);
         }
         else if(_loc4_ == "ldn")
         {
            this.mobileChouJiangNotify(_loc2_);
         }
         else if(_loc4_ == "gbroadcast")
         {
            this.gbroadcast(_loc2_);
         }
         else if(_loc4_ == "ccrp")
         {
            this.chaoGuanBaoXiang(_loc2_);
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
         else if(_loc4_ == "gbmres")
         {
            this.keyTitlesRes(_loc2_);
         }
         else if(_loc4_ == "al")
         {
            this.hostleave(_loc2_);
         }
         else if(_loc4_ == "ab")
         {
            this.hostGoBack(_loc2_);
         }
         else if(_loc4_ == "srres")
         {
            this.shareSuccess(_loc2_);
         }
         else if(_loc4_ == "rbce")
         {
            this.doubleHitEffect(_loc2_);
         }
         else if(_loc4_ == "ntbi")
         {
            this.ticketEnd(_loc2_);
         }
      }
      
      private function hostleave(param1:String) : void
      {
         EventCenter.dispatch("hostleave");
      }
      
      private function hostGoBack(param1:String) : void
      {
         EventCenter.dispatch("hostGoBack");
      }
      
      private function ServerLoginInfo(param1:Decode) : void
      {
         var _loc3_:int = 0;
         $.jscall("console.log","dmlgsuccess");
         this.secondTime = getTimer();
         this.serverId = param1.GetItemAsInt("sid");
         var _loc2_:Number = this.secondTime - this.firstTime;
         if(_loc2_ >= 2000)
         {
            _loc3_ = new Date().time / 1000;
            UserBehaviorLog.getInstance().sendChatLog(UserBehaviorLog.POINT_ID_LOGIN_DANMU,_loc3_,{
               "id":this.serverId + ":" + this.port,
               "lag":_loc2_
            });
         }
         if(this.myTimer == null)
         {
            this.myTimer = new Timer(this.per_keep_live * 1000,0);
            this.myTimer.addEventListener(TimerEvent.TIMER,this.KeepLive);
            this.myTimer.start();
         }
         else
         {
            this.myTimer.reset();
            this.myTimer.start();
         }
         this.login_status = true;
         if(this.joinGroupTimer == null)
         {
            this.joinGroupTimer = new Timer(1 * 1000,0);
            this.joinGroupTimer.addEventListener(TimerEvent.TIMER,this.CheckJoinGroup);
            this.joinGroupTimer.start();
         }
         else
         {
            this.joinGroupTimer.reset();
            this.joinGroupTimer.start();
         }
      }
      
      private function ServerChatContent(param1:Decode) : void
      {
         var _loc2_:int = 0;
         var _loc3_:String = null;
         var _loc4_:String = null;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         if(this.OnChatMsg != null)
         {
            _loc2_ = param1.GetItemAsInt("sender");
            if(_loc2_ == 4257531)
            {
               _loc3_ = param1.GetItem("content");
               _loc4_ = param1.GetItem("snick");
               _loc5_ = param1.GetItemAsNumber("go");
               _loc6_ = param1.GetItemAsNumber("ci");
               _loc7_ = param1.GetItemAsNumber("co");
               _loc8_ = param1.GetItemAsNumber("mi");
               _loc9_ = param1.GetItemAsNumber("mo");
               $.jscall("console.log","*****" + "  type=chatmessage" + "  sender=" + _loc2_ + "  snick=" + _loc4_ + "  content=" + _loc3_);
               $.jscall("console.log","*********" + " go=" + _loc5_ + "  ci=" + _loc6_ + "  co=" + _loc7_ + "  mi=" + _loc8_ + "  mo=" + _loc9_);
               $.jscall("console.log","4257531 receivemessagetime=*********" + new Date().time / 1000);
            }
            if(GlobalData.rg > 1 || GlobalData.pg > 1)
            {
               return;
            }
            this.OnChatMsg(param1);
         }
      }
      
      private function newServerChatContent(param1:String) : void
      {
         var _loc2_:Decode = null;
         var _loc3_:int = 0;
         var _loc4_:String = null;
         var _loc5_:String = null;
         var _loc6_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc10_:Number = NaN;
         if(this.newOnChatMsg != null)
         {
            _loc2_ = new Decode();
            _loc2_.Parse(param1);
            _loc3_ = _loc2_.GetItemAsInt("uid");
            if(_loc3_ == 4257531)
            {
               _loc4_ = _loc2_.GetItem("txt");
               _loc5_ = _loc2_.GetItem("nn");
               _loc6_ = _loc2_.GetItemAsNumber("go");
               _loc7_ = _loc2_.GetItemAsNumber("ci");
               _loc8_ = _loc2_.GetItemAsNumber("co");
               _loc9_ = _loc2_.GetItemAsNumber("mi");
               _loc10_ = _loc2_.GetItemAsNumber("mo");
               $.jscall("console.log","*****" + "  type=chatmessage" + "  sender=" + _loc3_ + "  snick=" + _loc5_ + "  content=" + _loc4_);
               $.jscall("console.log","*********" + " go=" + _loc6_ + "  ci=" + _loc7_ + "  co=" + _loc8_ + "  mi=" + _loc9_ + "  mo=" + _loc10_);
               $.jscall("console.log","4257531 receivemessagetime=*********" + new Date().time / 1000);
            }
            if(GlobalData.rg > 1 || GlobalData.pg > 1)
            {
               return;
            }
            this.newOnChatMsg(param1);
         }
      }
      
      private function ServerKeepLive(param1:Decode) : void
      {
         var _loc2_:int = param1.GetItemAsInt("tick");
         var _loc3_:int = param1.GetItemAsInt("usernum");
         var _loc4_:Encode = new Encode();
         _loc4_.AddItem("type","keeplive");
         _loc4_.AddItem_int("tick",_loc2_);
         _loc4_.AddItem_int("usernum",_loc3_);
         var _loc5_:String = _loc4_.Get_SttString();
         this.keep_online = this.keep_online + this.per_keep_live;
      }
      
      private function newServerKeepLive(param1:Decode) : void
      {
         param1.GetItemAsInt("mrkl");
      }
      
      private function ServerError(param1:Decode) : void
      {
         this.clean_conn_timer();
         var _loc2_:int = param1.GetItemAsInt("code");
         $.jscall("console.log","server_error1 [%d]",_loc2_);
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
      }
      
      private function ServerSetAdmin(param1:Decode) : void
      {
         var _loc2_:int = param1.GetItemAsInt("rescode");
         var _loc3_:int = param1.GetItemAsInt("userid");
         var _loc4_:int = param1.GetItemAsInt("opuid");
         var _loc5_:int = param1.GetItemAsInt("group");
         var _loc6_:String = param1.GetItem("adnick");
         var _loc7_:Encode = new Encode();
         _loc7_.AddItem_int("rescode",_loc2_);
         if(_loc2_ == 0)
         {
            _loc7_.AddItem_int("userid",_loc3_);
            _loc7_.AddItem_int("group",_loc5_);
            _loc7_.AddItem_int("opuid",_loc4_);
            _loc7_.AddItem("adnick",_loc6_);
         }
         var _loc8_:String = _loc7_.Get_SttString();
         $.jscall("console.log","setadm： [%s]",_loc8_);
         $.asTojs("room_data_setadm",_loc8_);
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
               $.jscall("console.log","dm ticket notify!");
            },int(Math.random() * 5000));
         }
         else if(rt == 2)
         {
            EventCenter.dispatch("PwdNotifyEvent",{"type":rtv});
         }
         else
         {
            clearTimeout(this.endTimeIndex);
            randTime = int(Math.random() * 30);
            $.jscall("console.log","ServerShowStatus2 =" + randTime);
            this.endTimeIndex = setTimeout(this.recommend,randTime * 1000);
         }
      }
      
      private function recommend() : void
      {
         EventCenter.dispatch("hostGoBack");
         $.jscall("console.log","nsStatechange:",this.endStr);
         $.asTojs("room_data_state",this.endStr);
         this.dispatcher.dispatchEvent(new Event("ServerShowStatus"));
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
      
      private function ServerUserEnter(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:String = _loc2_.GetItem("userinfo");
         var _loc4_:Decode = new Decode();
         _loc4_.Parse(_loc3_);
         var _loc5_:int = _loc4_.GetItemAsInt("id");
         var _loc6_:String = _loc4_.GetItem("name");
         var _loc7_:String = _loc4_.GetItem("nick");
         var _loc8_:int = _loc4_.GetItemAsInt("rg");
         var _loc9_:int = _loc4_.GetItemAsInt("bg");
         var _loc10_:int = _loc4_.GetItemAsInt("pg");
         var _loc11_:int = _loc4_.GetItemAsInt("rt");
         var _loc12_:Number = _loc4_.GetItemAsNumber("weight");
         var _loc13_:Number = _loc4_.GetItemAsNumber("strength");
         var _loc14_:int = _loc4_.GetItemAsInt("cps_id");
         var _loc15_:int = _loc4_.GetItemAsInt("m_deserve_lev");
         var _loc16_:int = _loc4_.GetItemAsInt("cq_cnt");
         var _loc17_:int = _loc4_.GetItemAsInt("best_dlev");
         var _loc18_:int = _loc4_.GetItemAsInt("level");
         var _loc19_:int = _loc4_.GetItemAsInt("curr_exp");
         var _loc20_:int = _loc4_.GetItemAsInt("up_need");
         var _loc21_:int = _loc4_.GetItemAsInt("exp");
         var _loc22_:int = _loc4_.GetItemAsInt("gt");
         var _loc23_:String = _loc4_.GetItem("shark");
         var _loc24_:int = _loc4_.GetItemAsInt("naat");
         var _loc25_:int = _loc4_.GetItemAsInt("nrt");
         var _loc26_:Encode = new Encode();
         _loc26_.AddItem_int("id",_loc5_);
         _loc26_.AddItem("name",_loc6_);
         _loc26_.AddItem("nick",_loc7_);
         _loc26_.AddItem_int("rg",_loc8_);
         _loc26_.AddItem_int("bg",_loc9_);
         _loc26_.AddItem_int("pg",_loc10_);
         _loc26_.AddItem_int("rt",_loc11_);
         _loc26_.AddItem_int("weight",_loc12_);
         _loc26_.AddItem_int("strength",_loc13_);
         _loc26_.AddItem_int("cps_id",_loc14_);
         _loc26_.AddItem_int("m_deserve_lev",_loc15_);
         _loc26_.AddItem_int("cq_cnt",_loc16_);
         _loc26_.AddItem_int("best_dlev",_loc17_);
         _loc26_.AddItem_int("level",_loc18_);
         _loc26_.AddItem_int("curr_exp",_loc19_);
         _loc26_.AddItem_int("up_need",_loc20_);
         _loc26_.AddItem_int("exp",_loc21_);
         _loc26_.AddItem_int("gt",_loc22_);
         _loc26_.AddItem("shark",_loc23_);
         _loc26_.AddItem_int("naat",_loc24_);
         _loc26_.AddItem_int("nrt",_loc25_);
         var _loc27_:String = _loc26_.Get_SttString();
         $.jscall("console.log","newuinfo： [%s]",_loc27_);
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_nstip",_loc26_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_nstip",param1);
         }
      }
      
      private function newServerUserEnter(param1:String) : void
      {
         $.jscall("console.log","newnewuinfo： [%s]",param1);
         $.asTojs("room_data_nstip2",param1);
      }
      
      private function buyDeserve(param1:String) : void
      {
         $.asTojs("room_data_buycq",param1);
      }
      
      private function baoxueTime(param1:String) : void
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
         $.jscall("console.log","common_call2:",_loc5_.Get_SttString());
      }
      
      private function rewardListResponse(param1:String) : void
      {
         $.asTojs("room_data_cqrank",param1);
         $.jscall("console.log","return_rewardList：",param1);
      }
      
      private function maskQrCodeNotify(param1:Decode) : void
      {
         var _loc2_:Number = param1.GetItemAsNumber("x_s");
         var _loc3_:Number = param1.GetItemAsNumber("y_s");
         var _loc4_:Number = param1.GetItemAsNumber("w_s");
         var _loc5_:Number = param1.GetItemAsNumber("h_s");
         var _loc6_:int = param1.GetItemAsInt("et");
         if(Param.maskObj == null)
         {
            Param.maskObj = new Object();
         }
         Param.maskObj.x_scale = _loc2_;
         Param.maskObj.y_scale = _loc3_;
         Param.maskObj.w_scale = _loc4_;
         Param.maskObj.h_scale = _loc5_;
         Param.maskObj.endtime = _loc6_;
         EventCenter.dispatch("maskNotify",null);
      }
      
      private function batterFxEffect(param1:String) : void
      {
         $.asTojs("room_data_giftbat2",param1);
         $.jscall("console.log","roomBatterFxRender：",param1);
      }
      
      private function onGiftNotify(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:String = _loc2_.GetItem("nn");
         var _loc4_:int = _loc2_.GetItemAsInt("ct");
         if(_loc4_ == 1)
         {
            EventCenter.dispatch("MobileRewardEvent",{
               "nameStr":_loc3_,
               "type":2,
               "time":getTimer()
            });
         }
         $.asTojs("room_data_olyw",param1);
         $.jscall("console.log","box_obj.Luck_Burst：",param1);
      }
      
      private function giftBroadcast(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:String = _loc2_.GetItem("sn");
         var _loc4_:String = _loc2_.GetItem("dn");
         var _loc5_:String = _loc2_.GetItem("gn");
         var _loc6_:int = _loc2_.GetItemAsInt("gc");
         var _loc7_:int = _loc2_.GetItemAsInt("drid");
         var _loc8_:int = _loc2_.GetItemAsInt("gs");
         var _loc9_:int = _loc2_.GetItemAsInt("rid");
         var _loc10_:int = _loc2_.GetItemAsInt("gfid");
         var _loc11_:int = _loc2_.GetItemAsInt("gb");
         var _loc12_:int = _loc2_.GetItemAsInt("es");
         var _loc13_:int = _loc2_.GetItemAsInt("bgl");
         var _loc14_:Encode = new Encode();
         _loc14_.AddItem("sn",_loc3_);
         _loc14_.AddItem("dn",_loc4_);
         _loc14_.AddItem("gn",_loc5_);
         _loc14_.AddItem_int("gc",_loc6_);
         _loc14_.AddItem_int("drid",_loc7_);
         _loc14_.AddItem_int("gs",_loc8_);
         _loc14_.AddItem_int("es",_loc12_);
         _loc14_.AddItem_int("rid",_loc9_);
         _loc14_.AddItem_int("gid",_loc10_);
         if(_loc12_ == 1 || _loc12_ == 2)
         {
            if(_loc13_ == 1 || _loc13_ == 3)
            {
               $.asTojs("room_data_giftbat1",param1);
               EventCenter.dispatch("GiftBroadcastEvent",{
                  "giftid":_loc10_,
                  "send":_loc3_,
                  "receive":_loc4_,
                  "gift":_loc5_,
                  "num":_loc6_,
                  "rid":_loc7_,
                  "giftStyle":_loc8_,
                  "haslb":_loc12_,
                  "type":2,
                  "time":getTimer()
               });
            }
         }
         else
         {
            $.asTojs("room_data_giftbat1",param1);
            EventCenter.dispatch("GiftBroadcastEvent",{
               "giftid":_loc10_,
               "send":_loc3_,
               "receive":_loc4_,
               "gift":_loc5_,
               "num":_loc6_,
               "rid":_loc7_,
               "giftStyle":_loc8_,
               "haslb":_loc12_,
               "type":2,
               "time":getTimer()
            });
         }
         $.jscall("console.log","live_gift_batter：",_loc14_.Get_SttString());
      }
      
      private function currentRoomGiftBroadcast(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("rid");
         var _loc4_:String = _loc2_.GetItem("vt");
         if(_loc4_ != "")
         {
            EventCenter.dispatch("VotesChanged",{"vt":_loc4_});
         }
         if(Param.isYinghun)
         {
            if(_loc3_ != 0 && (!GlobalData.yinghunRooms || GlobalData.yinghunRooms.indexOf(_loc3_.toString()) == -1))
            {
               return;
            }
         }
         else if(Param.isQQApp)
         {
            if(_loc3_ != 0 && (!GlobalData.qqappRooms || GlobalData.qqappRooms.indexOf(_loc3_.toString()) == -1))
            {
               return;
            }
         }
         $.asTojs("room_data_giftbat1",param1);
      }
      
      private function hbNotify(param1:String) : void
      {
         $.asTojs("room_data_giftbat1",param1);
         $.jscall("console.log","live_gift_batter3：",param1);
      }
      
      private function hbGetNotify(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("rpt");
         switch(_loc3_)
         {
            case 0:
               $.asTojs("room_data_giftbat1",param1);
               $.jscall("console.log","live_gift_batter5 ：",param1);
               break;
            case 1:
               $.jscall("treeReply",param1);
               break;
            case 2:
               $.asTojs("room_data_beastrep",param1);
               break;
            case 3:
               $.asTojs("room_data_sabonusget",param1);
               $.jscall("console.log","beastReply gateway : ",param1);
               break;
            default:
               $.jscall("console.log","unknown rpt type : ",_loc3_);
         }
      }
      
      private function hbForNewuserNotify(param1:String) : void
      {
         $.asTojs("room_data_giftbat1",param1);
         $.jscall("console.log","live_gift_batter6：",param1);
      }
      
      private function illegalNotify(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("ii");
         var _loc4_:Number = _loc2_.GetItemAsNumber("timestamp");
         var _loc5_:Number = _loc2_.GetItemAsNumber("now");
         $.asTojs("room_data_illchange",param1);
         $.jscall("console.log","illegaldt :",param1);
         Util.dispatchIllegal(_loc3_,_loc5_ - _loc4_);
      }
      
      private function rankUpdate(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("drid");
         var _loc4_:int = _loc2_.GetItemAsInt("sz");
         var _loc5_:int = _loc2_.GetItemAsInt("uid");
         var _loc6_:int = _loc2_.GetItemAsInt("rkt");
         var _loc7_:int = _loc2_.GetItemAsInt("rn");
         var _loc8_:String = _loc2_.GetItem("nk");
         if((_loc4_ & 2) != 0 && _loc7_ <= 10)
         {
            EventCenter.dispatch("RankBroadcastEvent",{
               "nickname":_loc8_,
               "rankType":_loc6_,
               "rankNum":_loc7_,
               "rid":_loc3_,
               "type":4,
               "time":getTimer()
            });
         }
         $.asTojs("room_data_cqrankupdate",param1);
         $.jscall("console.log","rankupdate：",param1);
      }
      
      private function userUpdate(param1:String) : void
      {
         $.asTojs("room_data_ulgrow",param1);
         $.jscall("console.log","userupdate：",param1);
      }
      
      private function levelIconNotify(param1:String) : void
      {
         $.asTojs("room_data_ulico",param1);
         $.jscall("console.log","levelIcon：",param1);
      }
      
      private function superDanmuBroadcast(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("sdid");
         var _loc4_:int = _loc2_.GetItemAsInt("trid");
         var _loc5_:String = _loc2_.GetItem("content");
         var _loc6_:int = _loc2_.GetItemAsInt("rid");
         var _loc7_:int = _loc2_.GetItemAsInt("gid");
         var _loc8_:Encode = new Encode();
         _loc8_.AddItem_int("sdid",_loc3_);
         _loc8_.AddItem_int("trid",_loc4_);
         _loc8_.AddItem("content",_loc5_);
         _loc8_.AddItem_int("rid",_loc6_);
         _loc8_.AddItem_int("gid",_loc7_);
         EventCenter.dispatch("MobileRewardEvent",{
            "did":_loc3_,
            "nrid":_loc4_,
            "supercontent":_loc5_,
            "crid":_loc6_,
            "cgid":_loc7_,
            "type":3,
            "time":getTimer()
         });
         $.jscall("console.log","superdm");
         if(GlobalData.OldModel)
         {
            $.asTojs("room_data_schat",_loc8_.Get_SttString());
         }
         else
         {
            $.asTojs("room_data_schat",param1);
         }
      }
      
      public function clean_conn_timer() : void
      {
         if(this.myTimer != null)
         {
            this.myTimer.stop();
            this.myTimer.removeEventListener(TimerEvent.TIMER,this.KeepLive);
            this.myTimer = null;
         }
         if(this._conn2 != null)
         {
            this._conn2.close();
            this._conn2.removeEventListener(TcpEvent.Conneted,this.onConn);
            this._conn2.removeEventListener(TcpEvent.RecvMsg,this.ParseMsg);
            this._conn2.removeEventListener(TcpEvent.SecurityError,this.onConn);
            this._conn2.removeEventListener(TcpEvent.Error,this.onConn);
            this._conn2.removeEventListener(TcpEvent.Closed,this.onConn);
            this._conn2 = null;
         }
      }
      
      private function christmasTree(param1:String) : void
      {
         $.jscall("treeReceived",param1);
      }
      
      private function christmasGift(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:String = _loc2_.GetItem("nm");
         var _loc4_:String = _loc2_.GetItem("mcnn");
         var _loc5_:int = _loc2_.GetItemAsInt("rid");
         EventCenter.dispatch("GiftBroadcastEvent",{
            "send":_loc4_,
            "receive":_loc3_,
            "rid":_loc5_,
            "haslb":1001,
            "time":getTimer()
         });
      }
      
      private function beastReceived(param1:String) : void
      {
         $.asTojs("room_data_beastrec",param1);
      }
      
      private function petInfo(param1:String) : void
      {
         var _loc4_:int = 0;
         var _loc5_:String = null;
         var _loc6_:String = null;
         var _loc7_:int = 0;
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
               _loc4_ = _loc2_.GetItemAsInt("rps");
               if(_loc4_ == 1)
               {
                  _loc5_ = _loc2_.GetItem("onick");
                  _loc6_ = _loc2_.GetItem("mnick");
                  _loc7_ = _loc2_.GetItemAsInt("rid");
                  EventCenter.dispatch("GiftBroadcastEvent",{
                     "send":_loc6_,
                     "receive":_loc5_,
                     "rid":_loc7_,
                     "haslb":1002,
                     "time":getTimer()
                  });
               }
               break;
            default:
               $.jscall("console.log","unknown pt type: ",_loc3_);
         }
      }
      
      private function deductionPoints(param1:String) : void
      {
         $.jscall("console.log","kfnotify");
         $.asTojs("room_data_ancpoints",param1);
      }
      
      private function nianNotify(param1:Decode) : void
      {
         var _loc2_:String = param1.GetItem("ct");
         var _loc3_:int = param1.GetItemAsInt("rid");
         var _loc4_:Decode = new Decode();
         _loc4_.Parse(_loc2_);
         var _loc5_:int = _loc4_.GetItemAsInt("hour");
         EventCenter.dispatch("GiftBroadcastEvent",{
            "rid":_loc3_,
            "hour":_loc5_,
            "haslb":2001,
            "time":getTimer()
         });
      }
      
      private function mobileChouJiangNotify(param1:String) : void
      {
         $.jscall("console.log","mobilecjnotify");
         $.asTojs("room_data_luckdrawcd",param1);
      }
      
      private function gbroadcast(param1:String) : void
      {
         var _loc4_:String = null;
         var _loc5_:Object = null;
         var _loc6_:int = 0;
         var _loc7_:String = null;
         var _loc8_:String = null;
         var _loc9_:String = null;
         var _loc10_:String = null;
         var _loc11_:String = null;
         var _loc12_:int = 0;
         var _loc13_:int = 0;
         var _loc14_:String = null;
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:int = _loc2_.GetItemAsInt("gbcss");
         if(_loc3_ == 0)
         {
            _loc4_ = _loc2_.GetItem("gbcc");
            if(_loc4_ != "")
            {
               _loc5_ = CommonUtils.decode(_loc4_);
               if(_loc5_)
               {
                  EventCenter.dispatch("GbroadcastEvent",{
                     "gbcss":_loc5_.gbcss,
                     "drid":_loc5_.drid,
                     "ronk":_loc5_.ronk,
                     "kw":_loc5_.kw,
                     "time":getTimer()
                  });
               }
            }
         }
         else if(_loc3_ == 4 || _loc3_ == 5)
         {
            _loc6_ = _loc2_.GetItemAsInt("drid");
            _loc7_ = _loc2_.GetItem("sn");
            _loc8_ = _loc2_.GetItem("dn");
            _loc9_ = _loc2_.GetItem("gfid");
            _loc10_ = _loc2_.GetItem("gn");
            _loc11_ = _loc2_.GetItem("htt");
            _loc12_ = _loc2_.GetItemAsInt("gvt");
            _loc13_ = _loc2_.GetItemAsInt("hvt");
            _loc14_ = "";
            if(_loc11_ == "1")
            {
               _loc14_ = "6";
            }
            else if(_loc11_ == "2")
            {
               _loc14_ = "66";
            }
            else if(_loc11_ == "3")
            {
               _loc14_ = "666";
            }
            EventCenter.dispatch("GbroadcastEvent",{
               "gbcss":_loc3_,
               "drid":_loc6_,
               "sn":_loc7_,
               "dn":_loc8_,
               "gfid":_loc9_,
               "gn":_loc10_,
               "num":_loc14_,
               "gvt":_loc12_,
               "hvt":_loc13_,
               "time":getTimer()
            });
         }
         $.jscall("console.log","gbroadcast");
      }
      
      private function chaoGuanBaoXiang(param1:String) : void
      {
         $.asTojs("room_data_sabonus",param1);
         $.jscall("console.log","chaoGuanBaoXiang");
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
         $.jscall("console.log","barrage room_data_sys:",param1);
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
      
      private function shareSuccess(param1:String) : void
      {
         $.asTojs("room_data_wbsharesuc",param1);
         $.jscall("console.log","share response");
      }
      
      private function doubleHitEffect(param1:String) : void
      {
         var _loc2_:Decode = new Decode();
         _loc2_.Parse(param1);
         var _loc3_:String = _loc2_.GetItem("sn");
         var _loc4_:String = _loc2_.GetItem("dn");
         var _loc5_:int = _loc2_.GetItemAsInt("gfid");
         var _loc6_:int = _loc2_.GetItemAsInt("ceid");
         var _loc7_:int = _loc2_.GetItemAsInt("drid");
         var _loc8_:int = _loc2_.GetItemAsInt("gs");
         var _loc9_:int = _loc2_.GetItemAsInt("bgl");
         if(_loc9_ == 1 || _loc9_ == 3)
         {
            EventCenter.dispatch("DoubleHitEffectEvent",{
               "giftid":_loc5_,
               "ceid":_loc6_,
               "send":_loc3_,
               "receive":_loc4_,
               "rid":_loc7_,
               "giftStyle":_loc8_,
               "haslb":100,
               "time":getTimer()
            });
         }
      }
      
      private function ticketEnd(param1:String) : void
      {
         $.asTojs("room_data_endchargelive",Param.eticket);
         EventCenter.dispatch("TipHide",{"type":1});
         EventCenter.dispatch("TicketStreamNotify",{"reset":true});
         $.jscall("console.log","ticket time end!");
      }
   }
}
