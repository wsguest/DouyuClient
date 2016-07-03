package cc.dy.model.net
{
   import org.puremvc.as3.patterns.proxy.Proxy;
   import org.puremvc.as3.interfaces.IProxy;
   import util.$;
   import flash.external.ExternalInterface;
   import common.event.EventCenter;
   import flash.utils.setTimeout;
   import util.UserBehaviorLog;
   import flash.events.Event;
   import flash.utils.clearInterval;
   import flash.utils.setInterval;
   import common.event.ObjectEvent;
   
   public class ClientProxy extends Proxy implements IProxy
   {
      // javascript proxy for browser 
      public static var NAME:String = "ClientProxy";
       
      private var _client:cc.dy.model.net.Client;
      
      private var flashProt:int = 0;
      
      private var protArr:Array;
      
      private var firstRepeatConnect:Boolean = true;
      
      private var fristConnect:Boolean = true;
      
      private var firstTimeOut:Boolean = true;
      
      private var _checkOnlineSeed:uint;
      
      private var countNet:int = 0;
      
      public function ClientProxy()
      {
         this.protArr = [843,844];
         super(NAME);
         this.flashProt = this.protArr[int(this.protArr.length * Math.random())];
         this.addJsCallback();
      }
      
      public function onSendByteCount(param1:Number) : void
      {
         if(this._client != null)
         {
            this._client.SendByteCount(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","client.SendByteCount is null!");
         }
      }
      
      public function onSendEmptyOrFullCount(param1:int, param2:int, param3:int, param4:String, param5:int, param6:String) : void
      {
         if(Param.IsIndex)
         {
            return;
         }
         if(this._client != null)
         {
            this._client.SendEmptyOrFullCount(param1,param2,param3,param4,param5,param6);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","client.SendEmptyOrFullCount is null!");
         }
      }
      
      private function addJsCallback() : void
      {
         if(ExternalInterface.available)
         {
            ExternalInterface.addCallback("js_newuser_client",this.MyNewUser);
            ExternalInterface.addCallback("js_userlogin",this.MyUserLogin);
            ExternalInterface.addCallback("js_verReque",this.verReque);
            ExternalInterface.addCallback("js_anotherlogin",this.anotherMyUserLogin);
            ExternalInterface.addCallback("js_sendmsg",this.MySendChatContent);
            ExternalInterface.addCallback("js_userlogout",this.MyUserLogout);
            ExternalInterface.addCallback("js_blackuser",this.MyBlackUser);
            ExternalInterface.addCallback("js_setadmin",this.MySetAdmin);
            ExternalInterface.addCallback("js_sendsize",this.MySendSize);
            ExternalInterface.addCallback("js_barrage",this.DisplayCommentLayer);
            ExternalInterface.addCallback("js_myblacklist",this.MyBlackList);
            ExternalInterface.addCallback("adverment",this.initLoad);
            ExternalInterface.addCallback("js_givePresent",this.onGivePresent);
            ExternalInterface.addCallback("js_giveGift",this.onGiveGift);
            ExternalInterface.addCallback("js_queryTask",this.onQueryTask);
            ExternalInterface.addCallback("js_newQueryTask",this.onNewQueryTaskNum);
            ExternalInterface.addCallback("js_obtainTask",this.onObtainTask);
            ExternalInterface.addCallback("js_roomSignUp",this.onSignUp);
            ExternalInterface.addCallback("js_keyTitles",this.keyTitles);
            ExternalInterface.addCallback("js_reportBarrage",this.reportBarrage);
            ExternalInterface.addCallback("js_exitFullScreen",this.exitFullScreen);
            ExternalInterface.addCallback("js_rewardList",this.rewardListRequest);
            ExternalInterface.addCallback("js_pmFeedback",this.emailNotifyFeedback);
            ExternalInterface.addCallback("js_query_giftPkg",this.query_giftPkg);
            ExternalInterface.addCallback("js_switchStream",this.switchStream);
            ExternalInterface.addCallback("js_superDanmuClick",this.superDanmuClick);
            ExternalInterface.addCallback("js_GetHongbao",this.hongbaoRequest);
            ExternalInterface.addCallback("js_effectVisible",this.hideEffect);
            ExternalInterface.addCallback("js_timeLoginTip",this.timeLoginTip);
            ExternalInterface.addCallback("js_breakRuleTip",this.breakRuleTip);
            ExternalInterface.addCallback("js_qqappList",this.qqappList);
            ExternalInterface.addCallback("js_sendhandler",this.sendHandler);
            ExternalInterface.addCallback("js_yinghunList",this.yinghunList);
            ExternalInterface.addCallback("js_shareSuccess",this.shareSuccess);
            ExternalInterface.addCallback("js_UserNoHandle",this.UserNoHandle);
            ExternalInterface.addCallback("js_UserHaveHandle",this.UserHaveHandle);
            ExternalInterface.addCallback("js_turn_on_activity",this.js_turn_on_activity);
            ExternalInterface.addCallback("js_buytickets_success",this.buyticketsSuccess);
         }
         EventCenter.addEventListener("DModelChangeEvent",this.__dmodelChange);
         EventCenter.addEventListener("SuperDanmuClickEvent",this.__superDanmuClick);
      }
      
      private function UserNoHandle(param1:* = null) : void
      {
         EventCenter.dispatch("UserNoHandleEvent");
         $.jscall("console.log","前端来消息UserNoHandleEvent");
      }
      
      private function UserHaveHandle() : void
      {
         EventCenter.dispatch("UserHaveHandleEvent");
      }
      
      public function MyNewUser() : void
      {
         if(this._client != null)
         {
            this._client.UserLogout();
            this._client.dispatcher.removeEventListener("ServerShowStatus",this.__ShowStatus);
            this._client = null;
            $.jscall("console.log","Error! [%s]","MyNewUser client  is not null!");
         }
         if(this.fristConnect)
         {
            setTimeout(this.__recodeFirst,2000);
         }
         this.fristConnect = false;
         this._client = new cc.dy.model.net.Client();
         this._client.ConnectServer(Param.ServerIp,Param.ServerPort,this.flashProt,this.OnConn);
         this._client.dispatcher.addEventListener("ServerShowStatus",this.__ShowStatus);
         $.jscall("console.log","server [%s]:[%s]",Param.ServerIp,Param.ServerPort);
         $.jscall("console.log","newUserclient[%s]","");
      }
      
      private function __recodeFirst() : void
      {
         var _loc1_:int = 0;
         if(this.firstTimeOut)
         {
            _loc1_ = new Date().time / 1000;
            UserBehaviorLog.getInstance().sendChatLog(UserBehaviorLog.POINT_ID_FIRST_LOGIN_,_loc1_,{"id":Param.ServerIp + ":" + Param.ServerPort});
         }
      }
      
      private function __ShowStatus(param1:Event) : void
      {
         sendNotification(Order.Show_Recommend_Request);
         if(Param.IS_HOSTLIVE == 1 || Param.usergroupid == "5")
         {
            sendNotification(Order.Hide_Load_Request);
         }
         else
         {
            sendNotification(Order.Hide_Load_Request);
            sendNotification(Order.Hide_Play_Request);
            sendNotification(Order.Hide_Video_Request);
         }
      }
      
      private function OnConn(param1:TcpEvent) : void
      {
         var _loc2_:int = 0;
         this.firstTimeOut = false;
         $.jscall("console.log","string is [%s]","OnConn");
         if(param1._param.type == 1)
         {
            GlobalData.isSecurError1 = false;
            sendNotification(Order.Room_Check_Request,null);
         }
         else if(param1._param.type == 3)
         {
            GlobalData.isSecurError1 = true;
            _loc2_ = param1._param.port;
            this.flashProt = _loc2_ == 843?844:843;
            if(this.firstRepeatConnect)
            {
               this.firstRepeatConnect = false;
               this.MyNewUser();
            }
         }
         if(this._checkOnlineSeed)
         {
            clearInterval(this._checkOnlineSeed);
         }
         this._checkOnlineSeed = setInterval(this.CheckOnline,120000);
      }
      
      private function CheckOnline() : void
      {
         var _loc1_:int = 0;
         if(!this._client._conn || !this._client._conn.is_connected)
         {
            $.jscall("console.log","berakOut Connection");
            this.MyNewUser();
            this.countNet++;
            _loc1_ = new Date().time / 1000;
            UserBehaviorLog.getInstance().sendChatLog(UserBehaviorLog.POINT_ID_LOGIN_SERVER_FAIL_,_loc1_,{
               "id":Param.ServerIp + ":" + Param.ServerPort,
               "lag":this.countNet
            });
         }
      }
      
      private function MyUserLogin(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.UserLogin(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","client.UserLogin is null!");
         }
      }
      
      private function verReque(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.verRequest(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","client.UserLogin is null!");
         }
      }
      
      private function anotherMyUserLogin(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.anotherUserLogin(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","client.UserLogin is null!");
         }
      }
      
      private function MySendChatContent(param1:String) : void
      {
         $.jscall("console.log","ChatMsg [%s]",param1);
         if(this._client != null)
         {
            this._client.SendChatContent(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","client.SendChatContent is null!");
         }
      }
      
      private function MyUserLogout() : void
      {
         if(this._client != null)
         {
            this._client.UserLogout();
            this._client = null;
         }
         else
         {
            $.jscall("console.log","Error! [%s]","client.Logout is null!");
         }
      }
      
      private function MyBlackUser(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.BlackUser(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","client.BlackUser is null!");
         }
      }
      
      private function MySetAdmin(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.SetAdmin(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","client.SetAdmin is null!");
         }
      }
      
      private function MySendSize(param1:String) : void
      {
      }
      
      private function DisplayCommentLayer(param1:Boolean) : void
      {
         $.jscall("console.log","damuState [%s]",param1);
         facade.sendNotification(Order.Comment_OpenHide_Request,{"status":param1});
      }
      
      private function MyBlackList(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.MyBlackList(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","client.MyBlackList is null!");
         }
      }
      
      private function initLoad() : void
      {
      }
      
      private function onGivePresent(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.givePresent(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","givePresent failed!!");
         }
      }
      
      private function onGiveGift(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.giveGift(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","givePresent failed!!");
         }
      }
      
      private function onQueryTask() : void
      {
         if(this._client != null)
         {
            this._client.queryTask();
         }
         else
         {
            $.jscall("console.log","Error! [%s]","queryTask failed!!");
         }
      }
      
      private function onNewQueryTaskNum() : void
      {
         if(this._client != null)
         {
            this._client.queryTaskNum();
         }
         else
         {
            $.jscall("console.log","Error! [%s]","queryTask failed!!");
         }
      }
      
      private function onObtainTask(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.obtainTask(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","obtainTask failed!!");
         }
      }
      
      private function onSignUp() : void
      {
         if(this._client != null)
         {
            this._client.roomSignUp();
         }
         else
         {
            $.jscall("console.log","Error! [%s]","onSignUp failed!!");
         }
      }
      
      private function keyTitles(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.setKeytitles(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","keyTitles failed!!");
         }
      }
      
      private function reportBarrage(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.setReportBarrage(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","reportBarrage failed!!");
         }
      }
      
      private function exitFullScreen() : void
      {
         EventCenter.dispatch("jsExitFullScreen",null);
      }
      
      private function rewardListRequest() : void
      {
         if(this._client != null)
         {
            this._client.requestRewardList();
         }
         else
         {
            $.jscall("console.log","Error! [%s]","requestRewardList failed!!");
         }
      }
      
      private function emailNotifyFeedback(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.emailNotifyResponse(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","emailNotifyFeedback failed!!");
         }
      }
      
      private function query_giftPkg(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.queryGiftPkg(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","emailNotifyFeedback failed!!");
         }
      }
      
      private function switchStream() : void
      {
      }
      
      private function superDanmuClick(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.jsSuperDanmuClickReq(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","superDanmuClick1 failed!!");
         }
      }
      
      private function hongbaoRequest(param1:String) : void
      {
         if(this._client != null)
         {
            this._client.hbRequest(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","hongbaoRequest failed!!");
         }
      }
      
      private function hideEffect(param1:int) : void
      {
         if(GlobalData.EFFECTLAYER)
         {
            GlobalData.EFFECTLAYER.visible = param1 == 1?false:true;
         }
      }
      
      private function timeLoginTip() : void
      {
         $.jscall("console.log","timetip");
         EventCenter.dispatch("StarttimeLoginTip");
      }
      
      private function breakRuleTip(param1:int) : void
      {
         $.jscall("console.log","quit normal=" + param1);
         if(param1 == 1)
         {
            EventCenter.dispatch("breakRuleTipEvent");
         }
      }
      
      private function __dmodelChange(param1:ObjectEvent) : void
      {
         if(this._client != null)
         {
            this._client.dmodelNotify(param1.data.type);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","dmodelNotify failed!!");
         }
      }
      
      private function __superDanmuClick(param1:ObjectEvent) : void
      {
         if(this._client != null)
         {
            this._client.superDanmuClickReq(param1.data);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","superDanmuClick failed!!");
         }
      }
      
      private function qqappList(param1:String) : void
      {
         if(param1)
         {
            GlobalData.qqappRooms = param1.split(",");
         }
      }
      
      private function sendHandler(param1:Array) : void
      {
         $.jscall("console.log","sendplayerres");
         EventCenter.dispatch("sendPlayerEvent",{"res":param1});
      }
      
      private function yinghunList(param1:String) : void
      {
         if(param1)
         {
            GlobalData.yinghunRooms = param1.split(",");
         }
      }
      
      private function shareSuccess(param1:Number) : void
      {
         if(this._client != null)
         {
            this._client.shareSuccess(param1);
         }
         else
         {
            $.jscall("console.log","Error! [%s]","share notify failed!");
         }
      }
      
      private function js_turn_on_activity(param1:String, param2:Boolean) : void
      {
         $.jscall("console.log","js_turn_on_activity",param1,param2);
         if(param1 == "666")
         {
            if(Boolean(Param.isYinghun) || Boolean(Param.isQQApp) || Boolean(Param.IsIndex) || Boolean(GlobalData.OldModel))
            {
               return;
            }
            if(param2)
            {
               sendNotification(Order.TURN_ON_AC666);
            }
         }
      }
      
      private function buyticketsSuccess() : void
      {
         EventCenter.dispatch("BuyticketsSuccess");
         $.jscall("console.log","buy tickets success callback");
      }
   }
}
