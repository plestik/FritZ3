package fritz3.utils.object {
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Dario Gieselaar
	 */
	public class ObjectPool {
		
		private static var _pool:Dictionary = new Dictionary();
		
		public function ObjectPool() {
			
		}
		
		public static function getObject ( objectClass:Class ):Object {
			var pool:Array = _pool[objectClass];
			if (!pool) {
				_pool[objectClass] = pool = [];
			}
			
			var object:Object = pool.shift();
			if (!object) {
				object = new objectClass();
			}
			return object;
		}
		
		public static function releaseObject ( object:Object ):void {
			if (object is IReleasable) {
				
			}
			var pool:Array = _pool[object.constructor];
			pool.push(object);
		}
		
		public static function flush ( ):void {
			_pool = new Dictionary();
		}
		
		
		
	}

}