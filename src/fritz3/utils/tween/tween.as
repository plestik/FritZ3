package fritz3.utils.tween {
	import fritz3.base.transition.TransitionData;
	/**
	 * ...
	 * @author Dario Gieselaar
	 */
		
	public function tween ( target:Object, propertyName:String, transitionData:TransitionData ):void {
		Tweener.engine.tween(target, propertyName, transitionData);
	}

}