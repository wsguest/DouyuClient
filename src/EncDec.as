package cc.dy.model.net
{
   public class Encode
   {
      // message encoder
      private static const SCAN_CHAR_REG:RegExp = /[\\/@]/;
       
      public var SttString:String = "";
      
      public function Encode()
      {
         super();
      }
      
      public function AddItem(key:String, value:String) : void
      {
         var keyStr:String = "";
         keyStr = key != null?this.scan_str(key) + "@=":"";
         this.SttString = this.SttString + (keyStr + this.scan_str(value) + "/");
      }
      
      public function AddItem_int(key:String, value:Number) : void
      {
         var keyStr:String = "";
         keyStr = key != null?this.scan_str(key) + "@=":"";
         this.SttString = this.SttString + (keyStr + this.scan_str(value.toString()) + "/");
      }
      
      public function Get_SttString() : String
      {
         return this.SttString;
      }
      
      private function scan_str(str:String) : String
      {
         var ch:String = null;
         if(str.search(SCAN_CHAR_REG) == -1)
         {
            return str;
         }
         var val:* = "";
         var i:int = 0;
         while(i < str.length)
         {
            ch = str.charAt(i);
            if(ch == "/")
            {
               val = val + "@S";
            }
            else if(ch == "@")
            {
               val = val + "@A";
            }
            else
            {
               val = val + ch;
            }
            i++;
         }
         return val;
      }
   }

   public class Decode
   {
      // message decoder, decode server message to dictionary 
      private var sItems:Object;
      
      private var _count:int;
      
      private var _rawString:String;
      
      public function Decode()
      {
         this.sItems = {};
         super();
      }
      
      public function get count() : int
      {
         return this._count;
      }
      
      public function get rawString() : String
      {
         return this._rawString;
      }
      
      public function Parse(sttString:String) : void
      {
         var ch:String = null;
         var chNext:String = null;
         if(sttString.charAt(sttString.length - 1) != "/")
         {
            sttString = sttString + "/";
         }
         this._rawString = sttString;
         var val:* = "";
         var key:String = "";
         var len:int = sttString.length;
         var count:int = 0;
         var i:int = 0;
         while(i < len)
         {
            ch = sttString.charAt(i);
            if(ch == "/")
            {
               this.sItems[key || count] = val;
               key = val = "";
               count++;
            }
            else if(ch == "@")
            {
               i++;
               chNext = sttString.charAt(i);
               if(chNext == "=")
               {
                  key = val;
                  val = "";
               }
               else if(chNext == "A")
               {
                  val = val + "@";
               }
               else if(chNext == "S")
               {
                  val = val + "/";
               }
            }
            else
            {
               val = val + ch;
            }
            i++;
         }
         this._count = count;
      }
      
      public function GetItem(key:String) : String
      {
         return this.sItems[key] || "";
      }
      
      public function GetItemAsInt(key:String) : int
      {
         return int(this.sItems[key]) || 0;
      }
      
      public function GetItemAsNumber(key:String) : Number
      {
         return Number(this.sItems[key]) || Number(0);
      }
      
      public function GetItemByIndex(key:int) : String
      {
         return this.sItems[key] || "";
      }
   }
}
