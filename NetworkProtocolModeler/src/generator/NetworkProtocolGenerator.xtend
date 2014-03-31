package generator

import generator.util.GeneratorUtil
import java.io.File
import java.io.FileWriter
import java.util.StringTokenizer
import model.BinaryField
import model.DataType
import model.Field
import model.IntegerField
import model.ProtocolModel
import model.StringField
import org.eclipse.jdt.core.ToolFactory
import org.eclipse.jdt.core.formatter.CodeFormatter
import org.eclipse.jface.text.Document
import model.BitField

class NetworkProtocolGenerator {
	private ProtocolModel model;
	private File basePath;

	new(ProtocolModel model, File basePath) {
		this.model = model
		this.basePath = basePath
	}

	def String getType(Field field) {
		if (field instanceof BinaryField)
			return "Byte[]";
		if (field instanceof BitField)
			return "Byte[]";
		if (field instanceof IntegerField)
			return "Long";
		if (field instanceof StringField)
			return "String";
		if (field instanceof DataType)
			return (field as DataType).typeName;
		throw new RuntimeException("Cannot happen.");

	}

	def process() {
		for (protocol : model.protocols) {
			var pkgPath = new StringBuilder();

			var tokenizer = new StringTokenizer(protocol.package, ".");
			while (tokenizer.hasMoreTokens) {
				pkgPath.append(tokenizer.nextToken)
				pkgPath.append('/')
			}
			var targetDir = new File(pkgPath.toString)
			if (!targetDir.exists)
				targetDir.mkdirs

			pkgPath.append(protocol.typeName)
			pkgPath.append(".java")

			var code = generateProtocol(protocol).toString
			var formatter = ToolFactory.createCodeFormatter(null)
			var textEdit = formatter.format(CodeFormatter.K_COMPILATION_UNIT, code, 0, code.length(), 0, "\n")
			var doc = new Document(code)
			textEdit.apply(doc)

			var sourceFile = new File(basePath, pkgPath.toString)
			var writer = new FileWriter(sourceFile)
			writer.append(doc.get)
			writer.close
		}
	}

	def private generateProtocol(DataType protocol) '''
�IF protocol.package != null && !protocol.package.equals("")�
package �protocol.package�;

�ENDIF�
import model.*;
import runtime.*;

public class �protocol.typeName� extends OrderedSerializable {
	
	�FOR v : protocol.fields�
		�generateVariableDef(v)�
	�ENDFOR�
	
	�FOR v : protocol.fields�
		�generateVariableGetter(v)�
		�generateVariableSetter(v)�
		
		�IF v instanceof BitField�
			�var long offset = 0�
			�FOR f : (v as BitField).components�
				�generateBitFieldGetter(v.name, f.name, offset, f.bitLength)�
				�generateBitFieldSetter(v.name, f.name, offset, f.bitLength)�
				�{
		offset += f.bitLength
		''
	}�
			�ENDFOR�
		�ENDIF�
	�ENDFOR�

	public VariableProps[] getSerializationOrder() {
		return new VariableProps[]
			�FOR v : protocol.fields BEFORE '{' SEPARATOR ', ' AFTER '};'�
				new VariableProps(�v.name�, �v.type�.class, �v.byteLen�, �v.unbounded�)
			�ENDFOR�
	}
}
	'''

	def private generateVariableDef(Field variable) '''
private �variable.type� �variable.name�;
	'''

	def private generateVariableGetter(Field variable) '''
public �variable.type� get�GeneratorUtil.capitalizeFirst(variable.name)�() {
	return this.�variable.name�;
}

	'''

	def private generateVariableSetter(Field variable) '''
public void set�GeneratorUtil.capitalizeFirst(variable.name)�(�variable.type� �variable.name�) {
	�IF variable.byteLen > 0�
		�IF variable.type.equals("Long")�
		if (Long.highestOneBit(�variable.name�) > �Math.pow(2, variable.byteLen - 1)�)
			throw new IllegalArgumentException("Specified value " + �variable.name� + " is out of range.");
		�ENDIF�
		�IF variable.type.equals("String")�
		if (�variable.name�.getBytes().length > �variable.byteLen�)
			throw new IllegalArgumentException("Specified value " + �variable.name� + " does not fit in string field.");
		�ENDIF�
		�IF variable.type.equals("Byte[]")�
		if (�variable.name�.length > �variable.byteLen�)
			throw new IllegalArgumentException("Specified value " + �variable.name� + " does not fit in string field.");
		�ENDIF�
	�ENDIF�
	this.�variable.name� = �variable.name�;
}

	'''

	def private generateBitFieldGetter(String bitField, String component, Long offset, Long len) '''
public Long get�GeneratorUtil.capitalizeFirst(component)�() {
	return �bitField�[�offset / 8�] | (�len.bitMaskForLen� << (offset % 8));
}
		'''

	def private generateBitFieldSetter(String bitField, String component, Long offset, Long len) '''
public void set�GeneratorUtil.capitalizeFirst(component)�(Long value) {
	�bitField�[�offset / 8�] &= ~(�len.bitMaskForLen� << (offset % 8));
	�bitField�[�offset / 8�] |= (value << (offset % 8));
}
		'''

	def private String bitMaskForLen(long len) {
		var sb = new StringBuffer;
		var count = len;
		while (count > 0) {
			sb.append('1')
			count = count - 1
		}
		return sb.toString
	}
}
