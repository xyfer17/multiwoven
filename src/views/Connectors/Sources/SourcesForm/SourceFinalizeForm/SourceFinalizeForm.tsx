import {
  Box,
  Heading,
  Input,
  Text,
  Textarea,
  useToast,
} from "@chakra-ui/react";
import SourceFormFooter from "../SourceFormFooter";
import { useFormik } from "formik";
import { useContext, useState } from "react";
import { SteppedFormContext } from "@/components/SteppedForm/SteppedForm";
import {
  CreateConnectorPayload,
  TestConnectionPayload,
} from "@/views/Connectors/types";
import { useNavigate } from "react-router-dom";
import { createNewConnector } from "@/services/connectors";

const finalDataSourceFormKey = "testSource";

const SourceFinalizeForm = (): JSX.Element | null => {
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const { state } = useContext(SteppedFormContext);
  const { forms } = state;
  const toast = useToast();
  const navigate = useNavigate();
  const finalDataSourceForm = forms.find(
    ({ stepKey }) => stepKey === finalDataSourceFormKey
  )?.data?.[finalDataSourceFormKey] as TestConnectionPayload | undefined;

  if (!finalDataSourceForm) return null;

  const formik = useFormik({
    initialValues: {
      connector_name: finalDataSourceForm.name,
      description: "",
    },
    onSubmit: async (formData) => {
      setIsLoading(true);
      try {
        const payload: CreateConnectorPayload = {
          connector: {
            configuration: finalDataSourceForm.connection_spec,
            name: finalDataSourceForm.name,
            connector_type: "source",
            connector_name: formData.connector_name,
            description: formData.description,
          },
        };

        const createConnectorResponse = await createNewConnector(payload);
        if (createConnectorResponse?.data) {
          toast({
            status: "success",
            title: "Success!!",
            description: "Source created successfully!",
            position: "bottom-right",
          });
          navigate("/setup/sources");
        } else {
          throw new Error();
        }
      } catch {
        toast({
          status: "error",
          title: "An error occurred.",
          description: "Something went wrong while creating source.",
          position: "bottom-right",
          isClosable: true,
        });
      } finally {
        setIsLoading(false);
      }
    },
  });

  return (
    <Box display="flex" justifyContent="center">
      <Box maxWidth="850px" width="100%">
        <form onSubmit={formik.handleSubmit}>
          <Box padding="24px" backgroundColor="gray.100" borderRadius="8px">
            <Heading size="md" fontWeight="600" marginBottom="24px">
              Finalize settings for this source
            </Heading>
            <Box>
              <Text marginBottom="8px" fontWeight="600">
                Source Name
              </Text>
              <Input
                name="connector_name"
                type="text"
                placeholder="Enter source name"
                background="#fff"
                marginBottom="24px"
                onChange={formik.handleChange}
                value={formik.values.connector_name}
                required
              />
              <Box display="flex">
                <Text marginBottom="8px" fontWeight="600">
                  Description
                </Text>{" "}
                <Text>(Optional)</Text>
              </Box>
              <Textarea
                name="description"
                placeholder="Enter a description"
                background="#fff"
                resize="none"
                onChange={formik.handleChange}
                value={formik.values.description}
              />
            </Box>
          </Box>
          <SourceFormFooter
            ctaName="Finish"
            ctaType="submit"
            isCtaLoading={isLoading}
          />
        </form>
      </Box>
    </Box>
  );
};

export default SourceFinalizeForm;
