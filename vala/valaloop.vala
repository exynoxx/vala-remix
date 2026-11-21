/* valaloop.vala
 *
 * Copyright (C) 2021  Rico Tzschichholz
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Rico Tzschichholz <ricotz@ubuntu.com>
 */

/**
 * Base class for all loop statements.
 */
public abstract class Vala.Loop : CodeNode {
	/**
	 * Specifies the loop condition.
	 */
	public Expression? condition {
		get {
			return _condition;
		}
		private set {
			_condition = value;
			if (_condition != null) {
				_condition.parent_node = this;
			}
		}
	}

	/**
	 * Specifies the loop body.
	 */
	public Block body {
		get {
			return _body;
		}
		private set {
			_body = value;
			_body.parent_node = this;
		}
	}

	Expression _condition;
	Block _body;

	protected Loop (Expression? condition, Block body, SourceReference? source_reference = null) {
		this.condition = condition;
		this.body = body;
		this.source_reference = source_reference;
	}

	public override void replace_expression (Expression old_node, Expression new_node) {
		if (condition == old_node) {
			condition = new_node;
		}
	}

	/**
	 * Hoists `s.length` out of a condition of the form `x OP s.length` (or
	 * `s.length OP x`), where s is an owned string local or in-parameter of the
	 * current subroutine that is never assigned or passed as ref/out inside
	 * the loop, and whose address is never taken nor captured by a closure
	 * (the subroutine must contain no lambdas). Strings are immutable, so the
	 * strlen() can be computed once before the loop.
	 *
	 * Returns the declaration of the hoisted temporary (to be emitted before
	 * the loop) and rewrites the condition, or returns null.
	 */
	protected Statement? hoist_string_length (CodeContext context) {
		unowned BinaryExpression? binary = condition as BinaryExpression;
		if (binary == null) {
			return null;
		}
		MemberAccess? len = string_length_access (binary.right) ?? string_length_access (binary.left);
		if (len == null) {
			return null;
		}
		unowned MemberAccess inner = (MemberAccess) len.inner;
		if (!inner.check (context) || inner.value_type == null
		    || inner.value_type.type_symbol != context.analyzer.string_type.type_symbol) {
			return null;
		}
		unowned Symbol sym = inner.symbol_reference;
		// unowned locals often alias mutable buffers, e.g. (string) data
		if (!((sym is LocalVariable && ((LocalVariable) sym).variable_type != null && ((LocalVariable) sym).variable_type.value_owned)
		    || (sym is Parameter && ((Parameter) sym).direction == ParameterDirection.IN))) {
			return null;
		}
		unowned Subroutine? sub = find_subroutine (sym);
		if (sub == null || sub != find_subroutine (context.analyzer.current_symbol) || sub.body == null) {
			return null;
		}

		string name = inner.member_name;
		bool unsafe = false;
		// no closures or address-of anywhere in the subroutine
		sub.body.accept (new TraverseVisitor (n => {
			if (n is LambdaExpression || (n is AddressofExpression && is_name (((AddressofExpression) n).inner, name))) {
				unsafe = true;
				return TraverseStatus.STOP;
			}
			return TraverseStatus.CONTINUE;
		}));
		// no assignment or ref/out use inside the loop
		accept_children (new TraverseVisitor (n => {
			if ((n is Assignment && is_name (((Assignment) n).left, name))
			    || (n is UnaryExpression && is_name (((UnaryExpression) n).inner, name)
			        && (((UnaryExpression) n).operator == UnaryOperator.REF || ((UnaryExpression) n).operator == UnaryOperator.OUT))) {
				unsafe = true;
				return TraverseStatus.STOP;
			}
			return TraverseStatus.CONTINUE;
		}));
		if (unsafe) {
			return null;
		}

		var local = new LocalVariable (null, get_temp_name (), len, len.source_reference);
		binary.replace_expression (len, new MemberAccess.simple (local.name, len.source_reference));
		return new DeclarationStatement (local, len.source_reference);
	}

	static MemberAccess? string_length_access (Expression expr) {
		unowned MemberAccess? ma = expr as MemberAccess;
		if (ma != null && ma.member_name == "length" && ma.inner is MemberAccess && ((MemberAccess) ma.inner).inner == null) {
			return ma;
		}
		return null;
	}

	static bool is_name (Expression? expr, string name) {
		return expr is MemberAccess && ((MemberAccess) expr).member_name == name;
	}

	static unowned Subroutine? find_subroutine (Symbol? sym) {
		while (sym != null && !(sym is Subroutine)) {
			sym = sym.parent_symbol;
		}
		return (Subroutine) sym;
	}
}
