package fritz3.display.graphics.parser  {
	import fritz3.display.core.DisplayValueType;
	import fritz3.display.layout.Align;
	import fritz3.style.PropertyParser;
	/**

	/**
	 * @author Dario Gieselaar
	 * @review 
	 * @copyright Frontier Information Technologies BV
	 * @package fritz3.display.graphics.parser
	 * 
	 * [Description]
	*/
	
	public class BackgroundPositionParser implements PropertyParser {
		
		protected static var _parser:BackgroundPositionParser
		
		protected static var _cachedProperties:Object;
		
		{ 
			_cachedProperties = { };
			_parser = new BackgroundPositionParser();
		}
		
		public function BackgroundPositionParser (  )  {
			
		}
		
		public function parseValue ( value:String ):Object {
			return _cachedProperties[value] ||= this.getPositionData(value);
		}
		
		protected function getPositionData ( value:String ):BackgroundPositionData {
			var data:BackgroundPositionData = new BackgroundPositionData();
			
			var horizontalFloat:String = Align.CENTER, verticalFloat:String = Align.CENTER;
			var offsetX:Number = 0, offsetY:Number = 0;
			var offsetXValueType:String = DisplayValueType.PERCENTAGE;
			var offsetYValueType:String = DisplayValueType.PERCENTAGE;
			
			var match:Array = value.match(/(^((center|(left|right)|(top|bottom))\s*)?((\d+)(%|px)?)?$)|(^(((center|left|right)\s*)?((\d+)(%|px)?)?)\s*(((center|top|bottom)\s*)?((\d+)(%|px)?)?)$)/);
			var val:Number, valueType:String;
			var type:String;
			if (match && match[1]) {
				type = match[5] ? "vertical" : "horizontal";
				val = match[7];
				switch(match[8]) {
					default:
					case "px":
					valueType = DisplayValueType.PIXEL;
					break;
					
					case "%":
					valueType = DisplayValueType.PERCENTAGE;
					break;
				}
				switch(type) {
					case "horizontal":
					horizontalFloat = match[3];
					offsetX = val;
					offsetXValueType = valueType;
					break;
					
					case "vertical":
					verticalFloat = match[3];
					offsetY = val;
					offsetYValueType = valueType;
					break;
				}
			} else if (match && match[9]) {
				if (match[10]) {
					if (match[12]) {
						horizontalFloat = match[12];
					}
					if (match[14]) {
						offsetX = match[14];
					}
					switch(match[15]) {
						default:
						case "px":
						offsetXValueType = DisplayValueType.PIXEL;
						break;
						
						case "%":
						offsetXValueType = DisplayValueType.PERCENTAGE;
						break;
					}
				}
				if (match[16]) {
					if (match[18]) {
						verticalFloat = match[18];
					}
					if (match[20]) {
						offsetY = match[20];
					}
					switch(match[21]) {
						default:
						case "px":
						offsetYValueType = DisplayValueType.PIXEL;
						break;
						
						case "%":
						offsetYValueType = DisplayValueType.PERCENTAGE;
						break;
					}
				}
			}
			
			data.horizontalFloat = horizontalFloat;
			data.offsetX = offsetX;
			data.offsetXValueType = offsetXValueType;
			
			data.verticalFloat = verticalFloat;
			data.offsetY = offsetY;
			data.offsetYValueType = offsetYValueType;
			return data;
		}
		
		public static function get parser ( ):BackgroundPositionParser { return _parser; }
		
	}

}