const obj = {};
obj.a = 1;
obj.b = 2;
delete obj.a;

// Remove List
/**
 * eval
 * with
 * Prototype Mutation
 * Dynamic property addtion
 * typeof based on control flow
 * any - like behaviour
 */

/**
 * Tagged Value Representation
 * 000 = object pointer
 * 001 = int32
 * 010 = float64 (boxed)
 * 011 = boolean
 * 100 = undefined
 * 101 = null
 */
let x = 5;
x = "hello";

/**
 * Allocate x on heap
 * Closure stores pointer to environment
 * closure -> env -> x
 */
function outer() {
  let x = 10;
  return function () {
    return x + 1;
  };
}
