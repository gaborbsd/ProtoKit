package parser;

import java.util.ArrayList;
import java.util.List;

import model.ProtocolProps;
import model.VariableProps;
import parser.NetworkProtocolParser.PkgContext;
import parser.NetworkProtocolParser.ProtocolContext;
import parser.NetworkProtocolParser.VariableDefContext;

public class NetworkProtocolTreeParser extends NetworkProtocolBaseListener {
	private List<ProtocolProps> protocolProps = new ArrayList<>();
	private ProtocolProps props;
	private List<VariableProps> varList;
	private String pkg = "";

	public static Class<?> getJavaType(String type) {
		switch (type) {
		case "int":
			return Integer.class;
		case "byte":
			return Byte.class;
		case "char":
			return Character.class;
		case "timestamp":
			return Long.class;
		}
		return null;
	}

	public static byte getJavaDefaultLen(String type) {
		switch (type) {
		case "int":
			return Integer.SIZE;
		case "byte":
			return Byte.SIZE;
		case "char":
			return Character.SIZE;
		case "timestamp":
			return Long.SIZE;
		}
		return 0;
	}

	@Override
	public void enterPkg(PkgContext ctx) {
		pkg = ctx.name.getText();
	}

	@Override
	public void enterProtocol(ProtocolContext ctx) {
		varList = new ArrayList<>();

		props = new ProtocolProps();
		props.setName(ctx.name.getText());
		props.setPkg(pkg);
		props.setVariableProps(varList);
		protocolProps.add(props);
	}

	@Override
	public void enterVariableDef(VariableDefContext ctx) {
		Class<?> type = getJavaType(ctx.type.getText());
		String len = ""; // XXX

		VariableProps props = new VariableProps();
		props.setName(ctx.name.getText());
		props.setType(type);
		if (len != null && !len.equals("")) {
			byte byteLen = Byte.parseByte(len);
			props.setByteLen(byteLen);
		}
		varList.add(props);
	}

	List<ProtocolProps> getModel() {
		return protocolProps;
	}
}
