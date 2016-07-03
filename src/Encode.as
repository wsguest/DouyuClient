package cc.dy.model.net
{
   public class Encode
   {
      
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
}
