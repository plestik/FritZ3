package fritz3.style.invalidation  {
	/**

	/**
	 * @author Dario Gieselaar
	 * @review 
	 * @copyright Frontier Information Technologies BV
	 * @package fritz3.style.invalidation
	 * 
	 * [Description]
	*/
	
	public class StyleManagerInvalidationSignal extends InvalidatableStyleSheetCollectorSignal {
		
		public function StyleManagerInvalidationSignal (  )  {
			super();
		}
		
		override public function dispatch ( ...rest ):void  {
			_dispatching = true;
			var node:StyleSheetCollectorNode = _firstNode, nextNode:StyleSheetCollectorNode;
			while (node) {
				if (node.remove) {
					nextNode = node.nextNode;
					this.remove(node.styleSheetCollector);
					node = nextNode;
				} else {
					node.styleSheetCollector.invalidateCollector();
					node = node.nextNode;
				}
			}
			_dispatching = false;
		}
		
	}

}