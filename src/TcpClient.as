package cc.dy.model.net
{
   import flash.events.EventDispatcher;
   import flash.net.Socket;
   import flash.system.Security;
   import util.$;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.SecurityErrorEvent;
   import flash.events.ProgressEvent;
   import flash.utils.ByteArray;
   import flash.errors.IOError;
   
   public class TcpEvent extends Event
   {
      // custom event for tcpClient
      public static var Conneted:String = "STT_TcpClient_Connected";
      
      public static var Error:String = "STT_TcpClient_Error";
      
      public static var Closed:String = "STT_TcpClient_Closed";
      
      public static var SecurityError:String = "STT_TcpClient_SecurityError";
      
      public static var RecvMsg:String = "STT_TcpClient_RecvMsg";
       
      public var _param:Object;
      
      public function TcpEvent(eventName:String, param2:Object = null, param3:Boolean = false, param4:Boolean = false)
      {
         this._param = param2;
         super(eventName,param3,param4);
      }
   }

   public class TcpClient extends EventDispatcher
   {
      // socket warpper   
      public var is_connected:Boolean;
      
      private var _socket:Socket;
      
      private var packet_len:int;
      
      private var isSecurError:Boolean = false;
      
      private var currentProt:int = 0;
      
      private var read_bytes:ByteArray;
      
      public function TcpClient(securError:Boolean)
      {
         super();
         this.isSecurError = securError;
         this.is_connected = false;
      }
      
      public function connect(ip:String = null, port:uint = 0, flashPort:int = 0) : void
      {
         this.close();
         this.currentProt = flashPort;
         if(this.isSecurError)
         {
            Security.loadPolicyFile("xmlsocket://" + ip + ":" + 844);
           //$.jscall("console.log","securityChange://" + ip + ":" + 844);
         }
         this._socket = new Socket();
         this._socket.endian = "littleEndian";
         this._socket.addEventListener(Event.CLOSE,this.closeHandler);
         this._socket.addEventListener(Event.CONNECT,this.connectHandler);
         this._socket.addEventListener(IOErrorEvent.IO_ERROR,this.ioErrorHandler);
         this._socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR,this.securityErrorHandler);
         this._socket.addEventListener(ProgressEvent.SOCKET_DATA,this.socketDataHandler);
         this._socket.connect(ip,port);
      }
      
      public function close() : void
      {
         if(this._socket != null)
         {
            this._socket.removeEventListener(Event.CLOSE,this.closeHandler);
            this._socket.removeEventListener(Event.CONNECT,this.connectHandler);
            this._socket.removeEventListener(IOErrorEvent.IO_ERROR,this.ioErrorHandler);
            this._socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR,this.securityErrorHandler);
            this._socket.removeEventListener(ProgressEvent.SOCKET_DATA,this.socketDataHandler);
            this._socket.close();
            this._socket = null;
         }
         this.is_connected = false;
      }
      
      public function sendmsg(sttStringMsg:String) : Boolean
      {
         var str_byte:ByteArray = null;
         var pack_len:int = 0;
         var head_byte:ByteArray = null;
         var str:String = sttStringMsg;
         try
         {
            str_byte = new ByteArray();
            str_byte.endian = "littleEndian";
            str_byte.writeUTFBytes(str);
            str_byte.writeByte(0);
            pack_len = 8 + str_byte.length;
            head_byte = new ByteArray();
            head_byte.endian = "littleEndian";
            head_byte.writeUnsignedInt(pack_len);
            head_byte.writeShort(689);
            head_byte.writeByte(0);
            head_byte.writeByte(0);
            if(this._socket != null)
            {
               this._socket.writeUnsignedInt(pack_len);
               this._socket.writeBytes(head_byte);
               this._socket.writeBytes(str_byte);
               this._socket.flush();
            }
         }
         catch(e:IOError)
         {
            this.close();
            return false;
         }
         return true;
      }
      
      private function parseNetData() : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:String = null;
         while(Boolean(this._socket) && Boolean(this._socket.bytesAvailable))
         {
            if(this.packet_len == 0)
            {
               if(this._socket.bytesAvailable < 4)
               {
                  return;
               }
               this.packet_len = this._socket.readInt();
            }
            if(this._socket.bytesAvailable < this.packet_len)
            {
               return;
            }
            _loc1_ = this._socket.readInt();
            _loc2_ = this._socket.readUnsignedShort();
            this._socket.readByte();
            this._socket.readByte();
            _loc3_ = this._socket.readUTFBytes(this.packet_len - 8);
            this.packet_len = 0;
            dispatchEvent(new TcpEvent(TcpEvent.RecvMsg,_loc3_));
         }
      }
      
      private function closeHandler(param1:Event) : void
      {
        //$.jscall("console.log","Tcp Close [%s]",param1.toString());
         this.dispatchEvent(new TcpEvent(TcpEvent.Closed,{"type":0}));
         this.close();
      }
      
      private function connectHandler(param1:Event) : void
      {
        //$.jscall("console.log","Tcp Connected [%s]",param1.toString());
         this.is_connected = true;
         this.dispatchEvent(new TcpEvent(TcpEvent.Conneted,{"type":1}));
      }
      
      private function ioErrorHandler(param1:IOErrorEvent) : void
      {
        //$.jscall("console.log","Tcp Error IO [%s]",param1.toString());
         this.dispatchEvent(new TcpEvent(TcpEvent.Error,{"type":2}));
         this.close();
      }
      
      private function securityErrorHandler(param1:SecurityErrorEvent) : void
      {
        //$.jscall("console.log","Tcp Error Security [%s]",param1.toString());
         this.dispatchEvent(new TcpEvent(TcpEvent.SecurityError,{
            "type":3,
            "port":this.currentProt
         }));
         this.close();
      }
      
      private function socketDataHandler(param1:ProgressEvent) : void
      {
         this.parseNetData();
      }
   }
}
