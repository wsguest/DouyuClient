package cc.dy.model.net
{
   public class Decode
   {
       
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
