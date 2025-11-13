import { IKeyRepository } from '../../../core/repositories/IKeyRepository';
import { KeyInfoDto } from '../../dto/KeyInfoDto';

/**
 * 列出密钥用例
 * 获取所有密钥并标记默认密钥
 */
export class ListKeysUseCase {
  constructor(private readonly keyRepository: IKeyRepository) {}

  /**
   * 执行列出密钥操作
   * @returns 密钥信息列表
   */
  async execute(): Promise<KeyInfoDto[]> {
    const collection = await this.keyRepository.getAll();
    const defaultKey = collection.getDefault();

    return collection.getAll().map((key) => ({
      name: key.name.value,
      maskedKey: key.getMaskedKey(),
      baseUrl: key.baseUrl?.value,
      note: key.note,
      createdAt: key.createdAt.toISOString(),
      isDefault: key.name.equals(defaultKey?.name),
    }));
  }
}
