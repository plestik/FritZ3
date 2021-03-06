package fritz3.display.graphics.gradient {
	import fritz3.display.core.DisplayValueType;
	import fritz3.utils.math.MathUtil;
	/**
	 * ...
	 * @author Dario Gieselaar
	 */
	public class GraphicsGradientData {
		
		public var type:String;
		public var angle:Number;
		public var focalPointRatio:Number;
		public var focalPointRatioValueType:String;
		
		public var offsetX:Number;
		public var offsetXValueType:String;
		
		public var offsetY:Number;
		public var offsetYValueType:String;
		
		public var gradientColors:Array;
		
		public var colors:Array;
		public var alphas:Array;
		
		protected var _ratios:Array;
		
		public function GraphicsGradientData ( ) {
			
		}
		
		public function invalidate ( ):void {
			this.colors = [], this.alphas = [];
			var gradientColor:GraphicsGradientColor;
			var cacheRatios:Boolean = true;
			for (var i:int, l:int = this.gradientColors.length; i < l; ++i) {
				gradientColor = this.gradientColors[i];
				this.colors[i] = gradientColor.color;
				this.alphas[i] = gradientColor.alpha;
				if (gradientColor.positionValueType != DisplayValueType.RATIO) {
					cacheRatios = false;
				}
			}
			
			if (cacheRatios) {
				_ratios = [];
				for (i = 0; i < l; ++i) {
					gradientColor = this.gradientColors[i];
					_ratios.push(gradientColor.position);
				}
			}
		}
		
		public function getRatios ( width:Number, height:Number ):Array {
			if (_ratios) {
				return _ratios;
			}
			
			var ratios:Array = [], gradientColor:GraphicsGradientColor, position:Number, positionValueType:String;
			var angle:Number = this.angle;
			var length:Number = MathUtil.getLineLength(width, height, Math.abs(angle) * Math.PI / 180);
			for (var i:int, l:int = this.gradientColors.length; i < l; ++i) {
				gradientColor = this.gradientColors[i];
				position = gradientColor.position;
				positionValueType = gradientColor.positionValueType;
				if (positionValueType == DisplayValueType.PIXEL) {
					position = (position / length) * 255;
				}
				ratios.push(position);
			}
			return ratios;
		}
		
		public function getFocalPointRatio ( width:Number, height:Number ):Number {
			if (this.focalPointRatioValueType != DisplayValueType.PIXEL) {
				return this.focalPointRatio;
			}
			
			var focalPoint:Number = this.focalPointRatio;
			var length:Number = MathUtil.getLineLength(width, height, angle * Math.PI / 180);
			focalPoint = focalPoint / (length / 2) * 2 -1;
			return focalPoint;
		}
		
		public function clone ( ):GraphicsGradientData {
			var data:GraphicsGradientData = new GraphicsGradientData();
			data.type = this.type;
			data.angle = this.angle;
			data.focalPointRatio = this.focalPointRatio;
			data.focalPointRatioValueType = this.focalPointRatioValueType;
			data.offsetX = this.offsetX;
			data.offsetXValueType = this.offsetXValueType;
			data.offsetY = this.offsetY;
			data.offsetYValueType = this.offsetYValueType;
			
			var i:int, l:int, gradientColors:Array = [], gradientColorFrom:GraphicsGradientColor, gradientColorTo:GraphicsGradientColor;
			for (i = 0, l = this.gradientColors ? this.gradientColors.length : 0; i < l; ++i) {
				gradientColorFrom = this.gradientColors[i];
				gradientColorTo = new GraphicsGradientColor();
				gradientColorTo.alpha = gradientColorFrom.alpha;
				gradientColorTo.color = gradientColorFrom.color;
				gradientColorTo.position = gradientColorFrom.position;
				gradientColorTo.positionValueType = gradientColorFrom.positionValueType;
				gradientColors[i] = gradientColorTo;
			}
			
			data.gradientColors = gradientColors;
			data.invalidate();
			
			return data;
		}
		
	}

}