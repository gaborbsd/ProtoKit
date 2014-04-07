package generator

import java.io.File
import java.io.FileWriter
import java.util.StringTokenizer
import model.BinaryField
import model.BitField
import model.CountField
import model.DataType
import model.Field
import model.IntegerField
import model.ListField
import model.ProtocolModel
import model.StringField
import org.eclipse.jdt.core.ToolFactory
import org.eclipse.jdt.core.formatter.CodeFormatter
import org.eclipse.jface.text.Document

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
		if (field instanceof ListField)
			return "List";
		if (field instanceof CountField)
			return "Long";
		if (field instanceof DataType)
			return (field as DataType).typeName;
		throw new RuntimeException("Cannot happen.");
	}

	def String getCollectionType(Field field) {
		if (field instanceof ListField)
			return (field.elementType as DataType).typeName;
		return null;
	}

	def String formatterClass(Field field) {
		return if(field.formatter != null) field.formatter.name else "null";
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

			//textEdit.apply(doc)
			var sourceFile = new File(basePath, pkgPath.toString)
			var writer = new FileWriter(sourceFile)
			writer.append(code)
			writer.close
		}
	}

	def private generateProtocol(DataType protocol) '''
�IF protocol.package != null && !protocol.package.equals("")�
package �protocol.package�;

�ENDIF�
import java.util.*;

import runtime.*;

public class �protocol.typeName� implements OrderedSerializable {
	�FOR v : protocol.fields�
		�IF !(v instanceof CountField)�
			�generateVariableDef(v)�
		�ENDIF�
	�ENDFOR�
	
	�generateInitialization(protocol)�
	
	�FOR v : protocol.fields�
	
		�IF v instanceof ListField�
			�generateListAccessors(v.name, v.collectionType)�
		�ELSEIF v instanceof CountField�
			�generateCountGetter(v.name, (v as CountField).ref.name)�
		�ELSE�
			�generateVariableGetter(v)�
			�generateVariableSetter(v)�
			
		�ENDIF�
		
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
				new VariableProps("�v.name�", "�v.type�", "�v.collectionType�", (byte)�v.byteLen�, �v.unbounded�, "�v.formatterClass�")
			�ENDFOR�
	}
}
	'''

	def private generateInitialization(DataType protocol) '''
		{
			�FOR v : protocol.fields�
				�IF v instanceof ListField�
					�v.name� = new ArrayList<>();
				�ENDIF�
			�ENDFOR�
		}
	'''

	def private generateVariableDef(Field variable) '''
		�IF variable instanceof ListField�
			private �variable.type�<�variable.collectionType�> �variable.name�;
		�ELSE�
			private �variable.type� �variable.name�;
		�ENDIF�
	'''

	def private generateVariableGetter(Field variable) '''
public �variable.type� get�variable.name.capitalizeFirst�() {
	return this.�variable.name�;
}

	'''

	def private generateVariableSetter(Field variable) '''
public void set�variable.name.capitalizeFirst�(�variable.type� �variable.name�) {
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
public Long get�component.capitalizeFirst�() {
	return (long)(�bitField�[�offset / 8�] | (�len.bitMaskForLen� << �offset % 8�));
}
		'''

	def private generateBitFieldSetter(String bitField, String component, Long offset, Long len) '''
public void set�component.capitalizeFirst�(Long value) {
	if (Long.highestOneBit(value) > �Math.pow(2, len - 1)�)
		throw new IllegalArgumentException("Specified value " + value + " is out of range.");
			
	�bitField�[�offset / 8�] = (byte)(�bitField�[�offset / 8�] & ~(�len.bitMaskForLen� << �offset % 8�));
	�bitField�[�offset / 8�] = (byte)(�bitField�[�offset / 8�] | (value << �offset % 8�));
}
		'''

	def private generateListAccessors(String varName, String listType) '''
public void add�varName.singularize.capitalizeFirst�(�listType� e) {
	�varName�.add(e);
}

public �listType� get�varName.singularize.capitalizeFirst�(int no) {
	return �varName�.get(no);
}

public void clear�varName.capitalizeFirst�() {
	�varName�.clear();
}

public void remove�varName.singularize.capitalizeFirst�(int no) {
	�varName�.remove(no);
}
	'''

	def private generateCountGetter(String countName, String ref) '''
public Long get�countName.capitalizeFirst�() {
	return (long)�ref�.size();
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

	def private String singularize(String str) {
		if (str.substring(str.length - 3, str.length).equals("ies"))
			return str.substring(0, str.length - 3) + "y";
		if (str.substring(str.length - 1, str.length).equals("s"))
			return str.substring(0, str.length - 1)
		return str;
	}

	def private String capitalizeFirst(String str) {
		var first = Character.toUpperCase(str.charAt(0));
		return first + str.substring(1);
	}
}
