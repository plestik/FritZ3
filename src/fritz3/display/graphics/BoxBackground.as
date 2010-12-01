﻿package fritz3.display.graphics {
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.CapsStyle;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.GraphicsGradientFill;
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import fritz3.base.injection.Injectable;
	import fritz3.binding.AccessType;
	import fritz3.binding.Binding;
	import fritz3.display.graphics.utils.getGradientMatrix;
	import fritz3.display.layout.Align;
	import fritz3.invalidation.Invalidatable;
	import fritz3.utils.ObjectPool;
	/**
	 * ...
	 * @author Dario Gieselaar
	 */
	public class BoxBackground implements RectangularBackground {
		
		protected var _parent:BackgroundParent;
		protected var _parameters:Object;
		
		protected var _width:Number;
		protected var _height:Number;
		
		protected var _backgroundColor:Object;
		protected var _backgroundAlpha:Number = 1;
		protected var _backgroundGradient:GraphicsGradientFill;
		protected var _backgroundGradientAngle:Number = 90;
		
		protected var _fillType:String = FillType.RECTANGLE;
		
		protected var _roundedCorners:Number = 0;
		protected var _topLeftCorner:Number = 0;
		protected var _topRightCorner:Number = 0;
		protected var _bottomLeftCorner:Number = 0;
		protected var _bottomRightCorner:Number = 0;
		
		protected var _border:Number = 0;
		protected var _borderPosition:String = BorderPosition.CENTER;
		protected var _borderTop:Number = 0;
		protected var _borderLeft:Number = 0;
		protected var _borderBottom:Number = 0;
		protected var _borderRight:Number = 0;
		protected var _borderAlpha:Number = 1;
		protected var _borderColor:Object;
		protected var _borderGradient:GraphicsGradientFill;
		protected var _borderGradientAngle:Number = 90;
		protected var _borderOffset:Number = 0;
		protected var _borderLineStyle:Array = LineStyle.SOLID;
		
		protected var _backgroundImage:DisplayObject;
		protected var _backgroundImageAlpha:Number = 1;
		protected var _backgroundImageHorizontalFloat:String = Align.LEFT;
		protected var _backgroundImageVerticalFloat:String = Align.TOP;
		protected var _backgroundImageOffsetX:Number = 0;
		protected var _backgroundImageOffsetY:Number = 0;
		protected var _backgroundImageRepeatX:Boolean;
		protected var _backgroundImageRepeatY:Boolean;
		protected var _backgroundImageScaleGrid:Rectangle;
		protected var _backgroundImageColor:Object;
		protected var _backgroundImageAntiAliasing:Boolean = false;
		
		protected var _graphics:Graphics;
		
		protected var _backgroundImageInvalidated:Boolean;
		protected var _backgroundBitmapData:BitmapData;
		
		protected var _linePatternData:BitmapData;
		
		public function BoxBackground ( parameters:Object = null ) {
			_parameters = parameters;
			//this.createBindings();
			this.setDefaultProperties();
			this.applyParameters();
		}
		
		protected function setDefaultProperties ( ):void {
			
		}
		
		protected function applyParameters ( ):void {
			var value:*;
			for (var name:String in _parameters) {
				this[name] = _parameters[name];
			}
		}
		
		public function draw ( displayObject:DisplayObject ):void {
			var buffer:Shape;
			
			if (displayObject is Shape) {
				_graphics = Shape(displayObject).graphics;
			} else if (displayObject is Sprite) {
				_graphics = Sprite(displayObject).graphics;
			} else {
				buffer = Shape(ObjectPool.getObject(Shape));
				_graphics = buffer.graphics;
			}
			
			_graphics.clear();
			
			this.drawBackground();
			this.drawBackgroundImage();
			this.drawBorder();
			
			_graphics = null;
			if (buffer) {
				ObjectPool.releaseObject(buffer);
			}
		}
		
		protected function drawBackground ( ):void {
			
			if (_backgroundColor != null) {
				var backgroundColor:uint = uint(_backgroundColor);
				_graphics.beginFill(backgroundColor, _backgroundAlpha);
				this.drawOutline();
				_graphics.endFill();
			}
			
			if (_backgroundGradient != null) {
				_graphics.beginGradientFill(_backgroundGradient.type, _backgroundGradient.colors, _backgroundGradient.alphas, _backgroundGradient.ratios, getGradientMatrix(_width, _height, _backgroundGradientAngle), _backgroundGradient.spreadMethod, _backgroundGradient.interpolationMethod, _backgroundGradient.focalPointRatio);
				this.drawOutline();
				_graphics.endFill();
			}
			
		}
		
		protected function drawBorder ( ):void {
			
			var leftOffset:Number = !isNaN(_borderLeft) ? (this.getBorderOffset(_borderLeft) + _borderLeft / 2) : 0;
			var rightOffset:Number = !isNaN(_borderRight) ? (this.getBorderOffset(_borderRight) + _borderRight / 2) : 0;
			var topOffset:Number = !isNaN(_borderTop) ? (this.getBorderOffset(_borderTop) + _borderTop / 2) : 0;
			var bottomOffset:Number = !isNaN(_borderBottom) ? (this.getBorderOffset(_borderBottom) + _borderBottom / 2) : 0;
		
			var borderWidth:Number = Math.max(_width, leftOffset + _width + rightOffset);
			var borderHeight:Number = Math.max(_height, topOffset + _height + bottomOffset);
			
			var width:Number = this.getBorderOffset(_borderLeft) + _width + this.getBorderOffset(_borderRight);
			var height:Number = this.getBorderOffset(_borderTop) + _height + this.getBorderOffset(_borderBottom);
			
			if (_borderGradient) {
				_borderGradient.matrix = getGradientMatrix(borderWidth, borderHeight, _borderGradientAngle);
			}
			
			if (_linePatternData) {
				_linePatternData.dispose();
				_linePatternData = null;
			}
			
			if (_borderLineStyle != LineStyle.SOLID) {
				
				_linePatternData = this.getLineBitmapPattern(borderWidth, borderHeight);
			}
			
			if (_border != _borderLeft) {
				_border = _borderLeft;
			}
			
			if (_fillType == FillType.ELLIPSE || (_border == _borderLeft && _border ==  _borderTop && _border == _borderBottom && _border == _borderRight)) {
				this.drawSingleBorder();
			} else {
				this.drawSeparateBorders();
			}
			
		}
		
		protected function drawSingleBorder ( ):void {
			
			if (!_border) {
				return;
			}
			
			
			var offset:Number = this.getBorderOffset(_border);
			
			var x:Number = -offset, y:Number = -offset, width:Number = _width + 2 * offset, height:Number = _height + 2 * offset;
			
			if (_borderLineStyle == LineStyle.SOLID) {
				if (_borderColor != null) {
					this.setLineStyle(_border);
					this.drawOutline(x, y, width, height);
				}
				if (_borderGradient) {
					this.setLineGradientStyle(_border);
					this.drawOutline(x, y, width, height);
				}
			} else {
				this.setLinePatternStyle(_border);			
				this.drawOutline(x, y, width, height);
			}
			
			_graphics.lineStyle();
			
			
		}
		
		protected function drawSeparateBorders ( ):void {
			var offset:Number;
			
			var graphics:Graphics = _graphics;
			
			var isSolidLineStyle:Boolean = (_borderLineStyle == LineStyle.SOLID);
			
			if (_borderTop) {
				offset = this.getBorderOffset(_borderTop);
				
				if (isSolidLineStyle) {
					this.setLineStyle(_borderTop);	
					graphics.moveTo(0, -offset); graphics.lineTo(_width, -offset);
					if (_borderGradient) {
						this.setLineGradientStyle(_borderTop);
						graphics.moveTo(0, -offset); graphics.lineTo(_width, -offset);
					}
				} else {
					this.setLinePatternStyle(_borderTop);
					graphics.moveTo(0, -offset); graphics.lineTo(_width, -offset);
				}
				
			}
			
			if (_borderRight) {
				offset = this.getBorderOffset(_borderRight);
				
				if (isSolidLineStyle) {
					this.setLineStyle(_borderRight);	
					if (!_borderTop) { graphics.moveTo(_width+offset, 0); } else { graphics.lineTo(_width+offset, -offset); } graphics.lineTo(_width+offset, _height);
					if (_borderGradient) {
						this.setLineGradientStyle(_borderRight);
						if (!_borderTop) { graphics.moveTo(_width+offset, 0); } else { graphics.lineTo(_width+offset, -offset); } graphics.lineTo(_width+offset, _height);
					}
				} else {
					this.setLinePatternStyle(_borderRight);
					if (!_borderTop) { graphics.moveTo(_width+offset, 0); } else { graphics.lineTo(_width+offset, -offset); } graphics.lineTo(_width+offset, _height);
				}
				
			}
			
			if (_borderBottom) {
				offset = this.getBorderOffset(_borderBottom);
				
				if (isSolidLineStyle) {
					this.setLineStyle(_borderBottom);	
					if (!_borderRight) { graphics.moveTo(_width, height); } else { graphics.lineTo(_width+offset, height); } graphics.lineTo(0, height);
					if (_borderGradient) {
						this.setLineGradientStyle(_borderBottom);
						if (!_borderRight) { graphics.moveTo(_width, height); } else { graphics.lineTo(_width+offset, height); } graphics.lineTo(0, height);
					}
				} else {
					this.setLinePatternStyle(_borderBottom);
					if (!_borderRight) { graphics.moveTo(_width, height); } else { graphics.lineTo(_width+offset, height); } graphics.lineTo(0, height);
				}
				
				
				
			}
				
			if (_borderLeft) {
				offset = this.getBorderOffset(_borderLeft);
				if (isSolidLineStyle) {
					this.setLineStyle(_borderLeft);	
					if (!_borderBottom) { graphics.moveTo(-offset, height); } else { graphics.lineTo(-offset, height); } graphics.lineTo(-offset,0);
					if (_borderGradient) {
						this.setLineGradientStyle(_borderLeft);
						if (!_borderBottom) { graphics.moveTo(-offset, height); } else { graphics.lineTo(-offset, height); } graphics.lineTo(-offset,0);
					}
				} else {
					this.setLinePatternStyle(_borderLeft);
					if (!_borderBottom) { graphics.moveTo(-offset, height); } else { graphics.lineTo(-offset, height); } graphics.lineTo(-offset,0);
				}
				
				graphics.lineStyle();
			}
		}
		
		protected function setLineStyle ( thickness:Number):void {
			_graphics.lineStyle(thickness, uint(_borderColor), _borderAlpha, true, LineScaleMode.NORMAL, CapsStyle.NONE);
		}
		
		protected function setLineGradientStyle ( thickness:Number ):void {
			_graphics.lineStyle(thickness, 0, _borderAlpha, true, LineScaleMode.NORMAL, CapsStyle.NONE);
			_graphics.lineGradientStyle(_borderGradient.type, _borderGradient.colors, _borderGradient.alphas, _borderGradient.ratios, _borderGradient.matrix, _borderGradient.spreadMethod, _borderGradient.interpolationMethod, _borderGradient.focalPointRatio);
		}
		
		protected function setLinePatternStyle ( thickness:Number ):void {
			_graphics.lineStyle(thickness, 0, 1, true, LineScaleMode.NORMAL, CapsStyle.NONE);
			var m:Matrix = new Matrix();
			var translateX:Number = !isNaN(_borderLeft) ? -(this.getBorderOffset(_borderLeft) + _borderLeft / 2) : 0;
			var translateY:Number = !isNaN(_borderTop) ? -(this.getBorderOffset(_borderTop) + _borderTop / 2) : 0;
			m.translate(translateX, translateY);
			_graphics.lineBitmapStyle(_linePatternData, m, false, false);
		}
		
		protected function getBorderOffset ( borderThickness:Number ):Number {
			if (isNaN(borderThickness)) {
				return 0;
			}
			var offset:Number = _borderOffset;
			switch(_borderPosition) {
				case BorderPosition.INSIDE:
				offset += borderThickness * -0.5;
				break;
				
				case BorderPosition.OUTSIDE:
				offset += borderThickness * 0.5;
				break;
			}
			return offset;
		}
		
		protected function drawBackgroundImage ( ):void {
			
			_backgroundImageInvalidated = false;
			
			if (_backgroundBitmapData) {
				_backgroundBitmapData.dispose();
				_backgroundBitmapData = null;
			}
			
			if (!_backgroundImage) {
				return;
			}
			
			this.getBackgroundImageBitmap();
			
			if (_backgroundBitmapData) {
				this.drawBackgroundBitmap();
			}
			
		}
		
		protected function drawBackgroundBitmap ( ):void {
			var graphics:Graphics = _graphics;
			var ct:ColorTransform = new ColorTransform();
			if (_backgroundImageColor) {
				ct.color = uint(_backgroundImageColor);
			}
			ct.alphaMultiplier = _backgroundImageAlpha;
			
			_backgroundBitmapData.colorTransform(_backgroundBitmapData.rect, ct);
			
			var p:Point = this.getBackgroundPosition();
			var m:Matrix = new Matrix();
			m.translate(p.x, p.y);
			graphics.beginBitmapFill(_backgroundBitmapData, m, true, _backgroundImageAntiAliasing);
			
			var width:Number = _backgroundImageRepeatX ? _width : _backgroundBitmapData.width;
			var height:Number = _backgroundImageRepeatY ? _height : _backgroundBitmapData.height;
			if(_backgroundImageRepeatX && _backgroundImageRepeatY) {
				this.drawOutline(p.x, p.y, width, height);
			} else {
				graphics.drawRect(p.x, p.y, width, height);
			}
			graphics.endFill();
			
		}
		
		protected function getBackgroundPosition ( ):Point {
			var p:Point = new Point();
			if (_backgroundImageRepeatX) {
				p.x = 0;
			} else {
				switch(_backgroundImageHorizontalFloat) {
					default: case Align.LEFT:
					p.x = 0;
					break;
					
					case Align.RIGHT:
					p.x = _width - _backgroundBitmapData.width;
					break;
					
					case Align.CENTER:
					p.x = _width / 2 - _backgroundBitmapData.width / 2;
					break;
				}
				p.x += _backgroundImageOffsetX;
			}
			
			if (_backgroundImageRepeatY) {
				p.y = 0;
			} else {
				switch(_backgroundImageVerticalFloat) {
					default: case Align.TOP:
					p.y = 0;
					break;
					
					case Align.BOTTOM:
					p.y = _height - _backgroundBitmapData.height;
					break;
					
					case Align.CENTER:
					p.y = _height / 2 - _backgroundBitmapData.height / 2;
					break;
				}
				p.y += _backgroundImageOffsetY;
			}
			
			return p;
		}
		
		protected function drawOutline ( x:Number = 0, y:Number = 0, width:Number = NaN, height:Number = NaN ):void {
			if (isNaN(width)) {
				width = _width;
			}
			if (isNaN(height)) {
				height = _height;
			}
			
			switch(_fillType) {
				case FillType.RECTANGLE:
				if (_roundedCorners || _topLeftCorner || _topRightCorner || _bottomLeftCorner || _bottomRightCorner) {
					_graphics.drawRoundRectComplex(x, y, width, height, _topLeftCorner, _topRightCorner, _bottomLeftCorner, _bottomRightCorner);
				} else {
					_graphics.drawRect(x, y, width, height);
				}
				break;
				
				case FillType.ELLIPSE:
				if (_width == _height) {
					_graphics.drawCircle(width / 2 + x, width / 2 + y, width / 2);
				} else {
					_graphics.drawEllipse(x, y, width, height);
				}
				break;
			}
		}
		
		protected function setBackgroundParent ( parent:BackgroundParent ):void {
			_parent = parent;
			if (_parent) {
				_parent.invalidateBackground();
			}
		}
		
		protected function invalidate ( ):void {
			if (_parent) {
				_parent.invalidateBackground();
			}
		}
		
		protected function invalidateBackgroundImage ( ):void {
			_backgroundImageInvalidated = true;
		}
		
		protected function getBackgroundImageBitmap ( ):void {
			if (_backgroundImage is Bitmap) {
				this.processBackgroundImageBitmap();
			} else {
				this.processBackgroundImageVector();
			}
		}
		
		protected function processBackgroundImageBitmap ( ):void {
			var bitmap:Bitmap = Bitmap(_backgroundImage);
			var bitmapData:BitmapData = bitmap.bitmapData;
			if (!_backgroundImageScaleGrid) {
				_backgroundBitmapData = bitmapData.clone();
			} else {
				_backgroundBitmapData = this.getScaledBitmapData(bitmapData);
			}
		}
		
		protected function getScaledBitmapData ( source:BitmapData ):BitmapData {
			
			var width:Number = _backgroundImageRepeatX ? _width : source.width;
			var height:Number = _backgroundImageRepeatY ? _height : source.height;
			
			var target:BitmapData = new BitmapData(width, height, true, 0x00FFFFFF);
			
			var sourceX1:Number = _backgroundImageScaleGrid.x, sourceX2:Number = sourceX1 + _backgroundImageScaleGrid.width;
			var sourceY1:Number = _backgroundImageScaleGrid.y, sourceY2:Number = sourceY1 + _backgroundImageScaleGrid.height;
			
			var targetX1:Number = sourceX1, targetX2:Number = width - (source.width - sourceX2);
			var targetY1:Number = sourceY1, targetY2:Number = height - (source.height - sourceY2);
			
			var scaleX:Number = (targetX2 - targetX1) / (sourceX2 - sourceX1);
			var scaleY:Number = (targetY2 - targetY1) / (sourceY2 - sourceY1);
			
			var m:Matrix = new Matrix(), rect:Rectangle;
			
			rect = new Rectangle();
			
			/*
			 * [x][ ][ ]
			 * [ ][ ][ ]
			 * [ ][ ][ ]
			 */
			rect.x = 0, rect.y = 0;
			rect.width = targetX1, rect.height = targetY1;
			target.draw(source, m, null, null, rect);
			
			/*
			 * [ ][x][ ]
			 * [ ][ ][ ]
			 * [ ][ ][ ]
			 */
			rect.x = targetX1, rect.y = 0;
			rect.width = targetX2 - targetX1;
			rect.height = targetY1;
			m.translate(-sourceX1+(sourceX1/scaleX),0);
			m.scale(scaleX, 1);
			target.draw(source, m, null, null, rect);
			
			/*
			 * [ ][ ][x]
			 * [ ][ ][ ]
			 * [ ][ ][ ]
			 */
			rect.x = targetX2, rect.y = 0;
			rect.width = width - targetX2, rect.height = targetY1;
			m.identity();
			m.translate(targetX2-sourceX2, 0);
			target.draw(source, m, null, null, rect);
			
			/*
			 * [ ][ ][ ]
			 * [x][ ][ ]
			 * [ ][ ][ ]
			 */
			rect.x = 0, rect.y = targetY1;
			rect.width = targetX1, rect.height = targetY2 - targetY1;
			m.identity();
			m.translate(0, -sourceY1 + (sourceY1 / scaleY));
			m.scale(1, scaleY);
			target.draw(source, m, null, null, rect);
			
			/*
			 * [ ][ ][ ]
			 * [ ][x][ ]
			 * [ ][ ][ ]
			 */
			rect.x = targetX1, rect.y = targetY1;
			rect.width = targetX2 - targetX1, rect.height = targetY2 - targetY1;
			m.identity();
			m.translate( -sourceX1 + (sourceX1 / scaleX), -sourceY1 + (sourceY1 / scaleY));
			m.scale(scaleX, scaleY);
			target.draw(source, m, null, null, rect);
			
			/*
			 * [ ][ ][ ]
			 * [ ][ ][x]
			 * [ ][ ][ ]
			 */
			rect.x = targetX2, rect.y = targetY1;
			rect.width = width - targetX2, rect.height = targetY2 - targetY1;
			m.identity();
			m.translate( targetX2-sourceX2, -sourceY1 + (sourceY1 / scaleY));
			m.scale(1, scaleY);
			target.draw(source, m, null, null, rect);
			
			/*
			 * [ ][ ][ ]
			 * [ ][ ][ ]
			 * [x][ ][ ]
			 */
			rect.x = 0, rect.y = targetY2;
			rect.width = targetX1, rect.height = height - targetY2;
			m.identity();
			m.translate(0, targetY2-sourceY2);
			target.draw(source, m, null, null, rect);
			
			/*
			 * [ ][ ][ ]
			 * [ ][ ][ ]
			 * [ ][x][ ]
			 */
			rect.x = targetX1, rect.y = targetY2;
			rect.width = targetX2 - targetX1, rect.height = height - targetY2;
			m.identity();
			m.translate(-sourceX1 + (sourceX1 / scaleX), targetY2-sourceY2);
			m.scale(scaleX, 1);
			target.draw(source, m, null, null, rect);
			
			/*
			 * [ ][ ][ ]
			 * [ ][ ][ ]
			 * [ ][ ][x]
			 */
			rect.x = targetX2, rect.y = targetY2;
			rect.width = width - targetX2, rect.height = height - targetY2;
			m.identity();
			m.translate(targetX2-sourceX2, targetY2-sourceY2);
			target.draw(source, m, null, null, rect);
			
			return target;
			
		}
		
		protected function processBackgroundImageVector ( ):void {
			// TODO: Implement
		}
		
		public function getLineBitmapPattern ( width:Number, height:Number ):BitmapData {
			var shape:Shape = Shape(ObjectPool.getObject(Shape));
			var bitmapData:BitmapData = new BitmapData(width, height, true, 0x00FFFFFF);
			
			var x:Number = 0, y:Number = 0, size:Number;
			var graphics:Graphics = shape.graphics;
			var ix:int, iy:int, l:int = _borderLineStyle.length;
			
			
			if (_borderColor != null) {
				var borderColor:uint = uint(_borderColor);
				graphics.beginFill(borderColor, _borderAlpha);
				this.fillLineBitmap(graphics, width, height);	
			}
			
			graphics.endFill();
			
			if (_borderGradient != null) {
				graphics.beginGradientFill(_borderGradient.type, _borderGradient.colors, _borderGradient.alphas, _borderGradient.ratios, getGradientMatrix(width, height, _borderGradientAngle), _borderGradient.spreadMethod, _borderGradient.interpolationMethod, _borderGradient.focalPointRatio);
			}
			
			this.fillLineBitmap(graphics, width, height);
			
			bitmapData.draw(shape, null, null, null, null, false);
			graphics.endFill();
			graphics.clear();
			ObjectPool.releaseObject(shape);
			return bitmapData;
		}
		
		protected function fillLineBitmap ( graphics:Graphics, width:Number, height:Number ):void {
			var size:Number, x:Number = 0, y:Number = 0, offset:Number, i:int;
			var l:int = _borderLineStyle.length;
			
			if (_borderLeft) {
				for (i = 0, x = 0, y = 0; y < height; ) {
					size = _borderLineStyle[i % l];
					if ((i & 1) == 0) {
						graphics.drawRect(x, y, _borderLeft, size);
					}
					y += size;
					++i;
				}
			}
			
			if (_borderTop) {
				for (i = 0, x = 0, y = 0; x < width; ) {
					size = _borderLineStyle[i % l];
					if ((i & 1) == 0) {
						graphics.drawRect(x, y, size, _borderTop);
					}
					x += size;
					++i;
				}
			}
			
			if(_borderRight) {
				for (i = 0, x = width, y = 0; y < height; ) {
					size = _borderLineStyle[i % l];
					if ((i & 1) == 0) {
						graphics.drawRect(x-_borderRight, y, _borderRight, size);
					}	
						y += size;
					++i;
				}
			}
			
			if (_borderBottom) {
				for (i = 0, x = 0, y = height; x < width; ) {
					size = _borderLineStyle[i % l];
					if ((i & 1) == 0) {
						graphics.drawRect(x, y-_borderBottom, size, _borderBottom);
					}
					x += size;
					++i;
				}
			}
			
		}
		
		public function get width ( ):Number { return _width; }
		public function set width ( value:Number ):void {
			if (_width != value) {
				_width = value;
				this.invalidate();
			}
		}
		
		public function get height ( ):Number { return _height; }
		public function set height ( value:Number ):void {
			if (_height != value) {
				_height = value;
				this.invalidate();
			}
		}
		
		public function get backgroundColor ( ):Object { return _backgroundColor; }
		public function set backgroundColor ( value:Object ):void {
			if (_backgroundColor != value) {
				_backgroundColor = value;
				this.invalidate();
			}
		}
		
		public function get backgroundAlpha ( ):Number { return _backgroundAlpha; }
		public function set backgroundAlpha ( value:Number ):void {
			if (_backgroundAlpha != value) {
				_backgroundAlpha = value;
				this.invalidate();
			}
		}
		
		public function get backgroundGradient ( ):GraphicsGradientFill { return _backgroundGradient; }
		public function set backgroundGradient ( value:GraphicsGradientFill ):void {
			if (_backgroundGradient != value) {
				_backgroundGradient = value;
				this.invalidate();
			}
		}
		
		
		
		public function get backgroundGradientAngle ( ):Number { return _backgroundGradientAngle; }
		public function set backgroundGradientAngle ( value:Number ):void {
			if(_backgroundGradientAngle != value) {
				_backgroundGradientAngle = value;
				this.invalidate();
			}
		}
		
		
		public function get fillType ( ):String { return _fillType; }
		public function set fillType ( value:String ):void {
			if (_fillType != value) {
				_fillType = value;
				this.invalidate();
			}
		}
		
		public function get roundedCorners ( ):Number { return _roundedCorners; }
		public function set roundedCorners ( value:Number ):void {
			if (_roundedCorners != value) {
				_roundedCorners = value;
				_topLeftCorner = _topRightCorner = _bottomLeftCorner = _bottomRightCorner = value;
				this.invalidate();
			}
		}
		
		public function get topLeftCorner ( ):Number { return _topLeftCorner; }
		public function set topLeftCorner ( value:Number ):void {
			if (_topLeftCorner != value) {
				_topLeftCorner = value;
				this.invalidate();
			}
		}
		
		public function get topRightCorner ( ):Number { return _topRightCorner; }
		public function set topRightCorner ( value:Number ):void {
			if (_topRightCorner != value) {
				_topRightCorner = value;
				this.invalidate();
			}
		}
		
		public function get bottomLeftCorner ( ):Number { return _bottomLeftCorner; }
		public function set bottomLeftCorner ( value:Number ):void {
			if (_bottomLeftCorner != value) {
				_bottomLeftCorner = value;
				this.invalidate();
			}
		}
		
		public function get bottomRightCorner ( ):Number { return _bottomRightCorner; }
		public function set bottomRightCorner ( value:Number ):void {
			if (_bottomRightCorner != value) {
				_bottomRightCorner = value;
				this.invalidate();
			}
		}
		
		public function get border ( ):Number { return _border; }
		public function set border ( value:Number ):void {
			if (_border != value) {
				_border = value;
				_borderLeft = _borderRight = _borderTop = _borderBottom = value;
				this.invalidate();
			}
		}
		
		public function get borderPosition ( ):String { return _borderPosition; }
		public function set borderPosition ( value:String ):void {
			if (_borderPosition != value) {
				_borderPosition = value;
				this.invalidate();
			}
		}
		
		public function get borderTop ( ):Number { return _borderTop; }
		public function set borderTop ( value:Number ):void {
			if (_borderTop != value) {
				_borderTop = value;
				this.invalidate();
			}
		}
		
		public function get borderLeft ( ):Number { return _borderLeft; }
		public function set borderLeft ( value:Number ):void {
			if (_borderLeft != value) {
				_borderLeft = value;
				this.invalidate();
			}
		}
		
		public function get borderBottom ( ):Number { return _borderBottom; }
		public function set borderBottom ( value:Number ):void {
			if (_borderBottom != value) {
				_borderBottom = value;
				this.invalidate();
			}
		}
		
		public function get borderRight ( ):Number { return _borderRight; }
		public function set borderRight ( value:Number ):void {
			if (_borderRight != value) {
				_borderRight = value;
				this.invalidate();
			}
		}
		
		public function get borderAlpha ( ):Number { return _borderAlpha; }
		public function set borderAlpha ( value:Number ):void {
			if (_borderAlpha != value) {
				_borderAlpha = value;
				this.invalidate();
			}
		}
		
		public function get borderColor ( ):Object { return _borderColor; }
		public function set borderColor ( value:Object ):void {
			if (_borderColor != value) {
				_borderColor = value;
				this.invalidate();
			}
		}
		
		public function get borderGradient ( ):GraphicsGradientFill { return _borderGradient; }
		public function set borderGradient ( value:GraphicsGradientFill ):void {
			if (_borderGradient != value) {
				_borderGradient = value;
				this.invalidate();
			}
		}
		
		public function get borderGradientAngle ( ):Number { return _borderGradientAngle; }
		public function set borderGradientAngle ( value:Number ):void {
			if(_borderGradientAngle != value) {
				_borderGradientAngle = value;
				this.invalidate();
			}
		}
		
		public function get borderOffset ( ):Number { return _borderOffset; }
		public function set borderOffset ( value:Number ):void {
			if (_borderOffset != value) {
				_borderOffset = value;
				this.invalidate();
			}
		}
		
		public function get borderLineStyle ( ):Array { return _borderLineStyle; }
		public function set borderLineStyle ( value:Array ):void {
			if (_borderLineStyle != value) {
				_borderLineStyle = value;
				this.invalidate();
			}
		}
		
		public function get backgroundImage ( ):DisplayObject { return _backgroundImage; }
		public function set backgroundImage ( value:DisplayObject ):void {
			if (_backgroundImage != value) {
				_backgroundImage = value;
				this.invalidate();
				this.invalidateBackgroundImage();
			}
		}
		
		public function get backgroundImageAlpha ( ):Number { return _backgroundImageAlpha; }
		public function set backgroundImageAlpha ( value:Number ):void {
			if (_backgroundImageAlpha != value) {
				_backgroundImageAlpha = value;
				this.invalidate();
			}
		}
		
		public function get backgroundImageHorizontalFloat ( ):String { return _backgroundImageHorizontalFloat; }
		public function set backgroundImageHorizontalFloat ( value:String ):void {
			if (_backgroundImageHorizontalFloat != value) {
				_backgroundImageHorizontalFloat = value;
				this.invalidate();
			}
		}
		
		public function get backgroundImageVerticalFloat ( ):String { return _backgroundImageVerticalFloat; }
		public function set backgroundImageVerticalFloat ( value:String ):void {
			if (_backgroundImageVerticalFloat != value) {
				_backgroundImageVerticalFloat = value;
				this.invalidate();
			}
		}
		
		public function get backgroundImageOffsetX ( ):Number { return _backgroundImageOffsetX; }
		public function set backgroundImageOffsetX ( value:Number ):void {
			if (_backgroundImageOffsetX != value) {
				_backgroundImageOffsetX = value;
				this.invalidate();
			}
		}
		
		public function get backgroundImageOffsetY ( ):Number { return _backgroundImageOffsetY; }	
		public function set backgroundImageOffsetY ( value:Number ):void {
			if (_backgroundImageOffsetY != value) {
				_backgroundImageOffsetY = value;
				this.invalidate();
			}
		}
		
		public function get backgroundImageRepeatX ( ):Boolean { return _backgroundImageRepeatX; }
		public function set backgroundImageRepeatX ( value:Boolean ):void {
			if (_backgroundImageRepeatX != value) {
				_backgroundImageRepeatX = value;
				this.invalidate();
			}
		}
		
		public function get backgroundImageRepeatY ( ):Boolean { return _backgroundImageRepeatY; }
		public function set backgroundImageRepeatY ( value:Boolean ):void {
			if (_backgroundImageRepeatY != value) {
				_backgroundImageRepeatY = value;
				this.invalidate();
			}
		}
		
		public function get backgroundImageScaleGrid ( ):Rectangle { return _backgroundImageScaleGrid; }
		public function set backgroundImageScaleGrid ( value:Rectangle ):void {
			if (_backgroundImageScaleGrid != value) {
				_backgroundImageScaleGrid = value;
				this.invalidate();
				this.invalidateBackgroundImage();
			}
		}
		
		public function get backgroundImageColor ( ):Object { return _backgroundImageColor; }
		public function set backgroundImageColor ( value:Object ):void {
			if(_backgroundImageColor != value) {
				_backgroundImageColor = value;
				this.invalidate();
				this.invalidateBackgroundImage();
			}
		}
		
		public function get backgroundImageAntiAliasing ( ):Boolean { return _backgroundImageAntiAliasing; }
		public function set backgroundImageAntiAliasing ( value:Boolean ):void {
			if (_backgroundImageAntiAliasing != value) {
				_backgroundImageAntiAliasing = value;
				this.invalidate();
				this.invalidateBackgroundImage();
			}
		}
		
		public function get parent ( ):BackgroundParent { return _parent; }
		public function set parent ( value:BackgroundParent ):void {
			if (_parent != value) {
				this.setBackgroundParent(value);
			}
		}
	}

}