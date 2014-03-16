package generator;

import java.lang.reflect.Type;

class VariableProps {
	private String name;
	private byte byteLen;
	private Type type;

	public VariableProps() {
		super();
	}

	public VariableProps(String name, Type type, byte byteLen) {
		super();
		this.name = name;
		this.type = type;
		this.byteLen = byteLen;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public byte getByteLen() {
		return byteLen;
	}

	public void setByteLen(byte byteLen) {
		this.byteLen = byteLen;
	}

	public Type getType() {
		return type;
	}

	public void setType(Type type) {
		this.type = type;
	}

	@Override
	public String toString() {
		return "VariableProps(" + name + ", " + type + ", " + byteLen + ")";
	}
}
