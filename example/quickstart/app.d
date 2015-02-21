import poodinis.dependency;

interface Database{};
class RelationalDatabase : Database {}

class DataWriter {
	@Autowire
	public Database database; // Automatically injected when class is resolved
}

void main() {
	auto container = DependencyContainer.getInstance();
	container.register!DataWriter;
	container.register!(Database, RelationalDatabase);

	auto writer = container.resolve!DataWriter;
}
