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
      
      public function AddItem(param1:String, param2:String) : void
      {
         var _loc3_:String = "";
         _loc3_ = param1 != null?this.scan_str(param1) + "@=":"";
         this.SttString = this.SttString + (_loc3_ + this.scan_str(param2) + "/");
      }
      
      public function AddItem_int(param1:String, param2:Number) : void
      {
         var _loc3_:String = "";
         _loc3_ = param1 != null?this.scan_str(param1) + "@=":"";
         this.SttString = this.SttString + (_loc3_ + this.scan_str(param2.toString()) + "/");
      }
      
      public function Get_SttString() : String
      {
         return this.SttString;
      }
      
      private function scan_str(param1:String) : String
      {
         var _loc4_:String = null;
         if(param1.search(SCAN_CHAR_REG) == -1)
         {
            return param1;
         }
         var _loc2_:* = "";
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc4_ = param1.charAt(_loc3_);
            if(_loc4_ == "/")
            {
               _loc2_ = _loc2_ + "@S";
            }
            else if(_loc4_ == "@")
            {
               _loc2_ = _loc2_ + "@A";
            }
            else
            {
               _loc2_ = _loc2_ + _loc4_;
            }
            _loc3_++;
         }
         return _loc2_;
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
      
      public function Parse(param1:String) : void
      {
         var _loc7_:String = null;
         var _loc8_:String = null;
         if(param1.charAt(param1.length - 1) != "/")
         {
            param1 = param1 + "/";
         }
         this._rawString = param1;
         var _loc2_:* = "";
         var _loc3_:String = "";
         var _loc4_:int = param1.length;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         while(_loc6_ < _loc4_)
         {
            _loc7_ = param1.charAt(_loc6_);
            if(_loc7_ == "/")
            {
               this.sItems[_loc3_ || _loc5_] = _loc2_;
               _loc3_ = _loc2_ = "";
               _loc5_++;
            }
            else if(_loc7_ == "@")
            {
               _loc6_++;
               _loc8_ = param1.charAt(_loc6_);
               if(_loc8_ == "=")
               {
                  _loc3_ = _loc2_;
                  _loc2_ = "";
               }
               else if(_loc8_ == "A")
               {
                  _loc2_ = _loc2_ + "@";
               }
               else if(_loc8_ == "S")
               {
                  _loc2_ = _loc2_ + "/";
               }
            }
            else
            {
               _loc2_ = _loc2_ + _loc7_;
            }
            _loc6_++;
         }
         this._count = _loc5_;
      }
      
      public function GetItem(param1:String) : String
      {
         return this.sItems[param1] || "";
      }
      
      public function GetItemAsInt(param1:String) : int
      {
         return int(this.sItems[param1]) || 0;
      }
      
      public function GetItemAsNumber(param1:String) : Number
      {
         return Number(this.sItems[param1]) || Number(0);
      }
      
      public function GetItemByIndex(param1:int) : String
      {
         return this.sItems[param1] || "";
      }
   }
}
