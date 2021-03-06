package fritz3.style {
	import fritz3.base.transition.TransitionData;
	import fritz3.base.transition.TransitionType;
	import fritz3.display.core.CyclePhase;
	import fritz3.invalidation.InvalidationHelper;
	import fritz3.invalidation.InvalidationPriorityTreshold;
	import fritz3.style.invalidation.StyleManagerInvalidationSignal;
	import fritz3.style.selector.ObjectCache;
	import fritz3.style.selector.Selector;
	import fritz3.style.selector.SelectorList;
	import fritz3.utils.object.getClass;
	import fritz3.utils.tween.Tweener;
	import org.osflash.signals.IDispatcher;
	import org.osflash.signals.ISignal;
	/**
	 * ...
	 * @author Dario Gieselaar
	 */
	public class StyleManager {
		
		public static const DEFAULT_STYLESHEET_ID:String = null;
		
		protected static var _firstNodeByID:Object;
		protected static var _lastNodeByID:Object;
		
		protected static var _onChange:StyleManagerInvalidationSignal;
		protected static var _invalidationHelper:InvalidationHelper;
		
		{
			_firstNodeByID = { };
			_lastNodeByID = { };
			
			_onChange = new StyleManagerInvalidationSignal();
			_invalidationHelper = new InvalidationHelper();
			_invalidationHelper.append(dispatchChange);
			_invalidationHelper.priority = InvalidationPriorityTreshold.DISPLAY_INVALIDATION + 1;
		}
		
		public function StyleManager ( ) {
			
		}
		
		public static function reset ( ):void {
			_invalidationHelper.invalidateMethod(dispatchChange);
			_invalidationHelper.invalidateMethod(clearObjectCache);
		}
		
		protected static function dispatchChange ( ):void {
			_onChange.dispatch();
		}
		
		protected static function clearObjectCache ( ):void {
			ObjectCache.clearCache();
		}
		
		public static function addRule ( styleRule:StyleRule ):void {
			var styleSheetID:String = styleRule.styleSheetID;
			var lastNode:StyleRule = _lastNodeByID[styleSheetID];
			if (!lastNode) {
				_firstNodeByID[styleSheetID] = styleRule;
			} else {
				lastNode.nextNode = styleRule;
				styleRule.prevNode = lastNode;
			}
			
			_lastNodeByID[styleSheetID] = styleRule;
			
			_invalidationHelper.invalidateMethod(dispatchChange);
		}
		
		public static function removeRule ( styleRule:StyleRule ):void {
			var styleSheetID:String = styleRule.styleSheetID;
			var prevNode:StyleRule = styleRule.prevNode, nextNode:StyleRule = styleRule.nextNode;
			if (prevNode) {
				prevNode.nextNode = nextNode;
			}
			if (nextNode) {
				nextNode.prevNode = prevNode;
			}
			
			if (_firstNodeByID[styleSheetID] == styleRule) {
				_firstNodeByID[styleSheetID] = nextNode;
			}
			
			if (_lastNodeByID[styleSheetID] == styleRule) {
				_lastNodeByID[styleSheetID] = prevNode;
			}
			
			_invalidationHelper.invalidateMethod(dispatchChange);
		}
		
		public static function parseXML ( xml:XML ):void {
			
			const children:XMLList = xml.children();
			var child:XML;
			var i:int = 0;
			const l:int = children.length();
			var rule:StyleRule;
			for (; i < l; ++i) {
				child = children[i];
				rule = getStyleRuleFromXML(child);
				rule.styleSheetID = child.@styleSheetID != undefined ? child.@styleSheetID : null;
				addRule(rule);
			}
			
			
			_invalidationHelper.invalidateMethod(dispatchChange);
		}
		
		protected static function getStyleRuleFromXML ( xml:XML ):StyleRule {
			var rule:StyleRule = new StyleRule();
			var children:XMLList = xml.property;
			var i:int = 0;
			var l:int = children.length();
			rule.selectorList = new SelectorList(xml.@where.toString());
			var child:XML, propertyName:String, propertyValue:*, target:String;
			var dotIndex:int, data:PropertyData;
			var nodes:Object = { };
			for (; i < l; ++i) {
				child = children[i];
				target = null;
				propertyName = child.@name.toString();
				if ((dotIndex = propertyName.indexOf(".")) != -1) {
					target = propertyName.substr(0, dotIndex);
					propertyName = propertyName.substr(dotIndex+1);
				} 
				if (child.hasSimpleContent()) {
					propertyValue = getSimpleValue(child.toString());
				} else {
					propertyValue = child.children()[0];
				}
				data = new PropertyData();
				data.propertyName = propertyName;
				data.value = propertyValue;
				data.target = target;
				rule.append(data);
				(nodes[target] ||= { } )[propertyName] = data;
			}
			
			children = xml.transition;
			l = children.length();
			var transitionData:TransitionData, type:String, duration:Number, delay:Number, easeStr:String, ease:Function, phase:String;
			for (i = 0; i < l; ++i) {
				child = children[i];
				propertyName = child.@name.toString();
				type = child.@type == undefined ? TransitionType.TO : child.@type.toString();
				duration = child.@duration;
				delay = child.@delay == undefined ? 0 : child.@delay;
				phase = child.@phase == undefined ? CyclePhase.LIVE : child.@phase.toString();
				if (child.@ease != undefined) {
					easeStr = child.@ease.toString();
					ease = Tweener.engine.getEaseFunction(easeStr);
				} else {
					ease = Tweener.engine.defaultEaseFunction;
				}
				
				
				if ((dotIndex = propertyName.indexOf(".")) != -1) {
					target = propertyName.substr(0, dotIndex);
					propertyName = propertyName.substr(dotIndex+1);
				} else {
					target = null;
				}
				
				transitionData = new TransitionData();
				transitionData.target = target;
				transitionData.propertyName = propertyName;
				transitionData.type = type;
				transitionData.duration = duration;
				transitionData.delay = delay;
				transitionData.ease = ease;
				transitionData.cyclePhase = phase;
				
				if (transitionData.type == TransitionType.FROM) {
					if (child.hasSimpleContent()) {
						propertyValue = getSimpleValue(child.toString());
					} else {
						propertyValue = child.children()[0];
					}
					transitionData.from = propertyValue;
				}
				rule.append(transitionData);
			}
			return rule;
		}
		
		protected static function replaceDash ( match:String, ...args ):String {
			return match.substr(1,1).toUpperCase();
		}
		
		protected static function getSimpleValue ( string:String ):* {
			var value:* = string;
			switch(string) {
				case "true":
				value = true;
				break;
				
				case "false":
				value = false;
				break;
				
				case "NaN":
				value = NaN;
				break;
				
				case "Number.MAX_VALUE":
				value = Number.MAX_VALUE;
				break;
				
				case "Number.MIN_VALUE":
				value = Number.MIN_VALUE;
				break;
				
				case "null":
				value = null;
				break;
			}
			
			return value;	
		}
		
		public static function getFirstRule ( styleSheetID:String = null ):StyleRule {
			_invalidationHelper.invalidateMethod(clearObjectCache);
			return _firstNodeByID[styleSheetID];
		}
		
		public static function get onChange ( ):StyleManagerInvalidationSignal {
			return _onChange;
		}
		
	}

}